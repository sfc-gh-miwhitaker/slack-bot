"""
Cortex Agent Client
Clean, simplified Cortex Agent API client with streaming response handling,
real-time status callbacks, SQL query extraction, and verified query detection.
"""

import os
import json
import re
import requests
import pandas as pd
from typing import Dict, List, Any, Optional, Callable
from dataclasses import dataclass, field


@dataclass
class AgentResponse:
    """Structured response from Cortex Agent."""
    text: str = ""
    sql_queries: List[str] = field(default_factory=list)
    citations: str = ""
    suggestions: List[str] = field(default_factory=list)
    verified_query_used: bool = False
    planning_steps: List[str] = field(default_factory=list)
    thinking_content: List[str] = field(default_factory=list)
    data: Optional[pd.DataFrame] = None
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for Slack display."""
        return {
            'text': self.text,
            'sql_queries': self.sql_queries,
            'citations': self.citations,
            'suggestions': self.suggestions,
            'verified_query_used': self.verified_query_used,
            'planning_steps': self.planning_steps,
            'data': self.data
        }


class CortexAgent:
    """
    Cortex Agent API client with streaming support.
    
    Usage:
        agent = CortexAgent(agent_url, pat)
        response = agent.chat("How many tickets by service type?")
        print(response.text)
        print(response.data)
    """
    
    def __init__(
        self, 
        agent_url: str, 
        pat: str,
        connection=None,
        debug: bool = False
    ):
        self.agent_url = agent_url
        self.pat = pat
        self.connection = connection
        self.debug = debug
        
        self.planning_steps: List[str] = []
        self.thinking_content: List[str] = []
        self.sql_queries: List[str] = []
        self.verified_query_used: bool = False
    
    def chat(
        self, 
        query: str,
        on_status: Optional[Callable[[str, List[str]], None]] = None
    ) -> Dict[str, Any]:
        """
        Send a query to the Cortex Agent and get a response.
        
        Args:
            query: User's natural language question
            on_status: Optional callback for real-time status updates
                       Signature: on_status(status_message, all_steps)
        
        Returns:
            Dict with response data (text, sql_queries, data, etc.)
        """
        self.planning_steps = []
        self.thinking_content = []
        self.sql_queries = []
        self.verified_query_used = False
        
        response = self._stream_request(query, on_status)
        
        if response.sql_queries and self.connection:
            response.data = self._execute_sql(response.sql_queries[0])
        
        return response.to_dict()
    
    def _stream_request(
        self, 
        query: str,
        on_status: Optional[Callable] = None
    ) -> AgentResponse:
        """Make streaming request to Cortex Agent API."""
        
        payload = {
            "messages": [{
                "role": "user",
                "content": [{"type": "text", "text": query}]
            }],
            "tool_choice": {"type": "auto"},
            "stream": True
        }
        
        headers = {
            "X-Snowflake-Authorization-Token-Type": "PROGRAMMATIC_ACCESS_TOKEN",
            "Authorization": f"Bearer {self.pat}",
            "Content-Type": "application/json",
            "Accept": "application/json"
        }
        
        response = AgentResponse()
        current_event = None
        accumulated_text = ""
        current_thinking = ""
        
        try:
            http_response = requests.post(
                self.agent_url,
                headers=headers,
                data=json.dumps(payload),
                timeout=120,
                stream=True
            )
            http_response.raise_for_status()
            
            for line in http_response.iter_lines():
                if not line:
                    continue
                    
                line_decoded = line.decode('utf-8')
                
                if line_decoded.startswith('event: '):
                    current_event = line_decoded[7:].strip()
                    continue
                
                if not line_decoded.startswith('data: '):
                    continue
                
                data_content = line_decoded[6:].strip()
                
                if data_content == '[DONE]':
                    break
                
                if data_content.startswith('['):
                    continue
                
                try:
                    json_data = json.loads(data_content)
                except json.JSONDecodeError:
                    continue
                
                if current_event == 'response.status':
                    if 'message' in json_data:
                        status_msg = json_data['message']
                        self.planning_steps.append(status_msg)
                        response.planning_steps.append(status_msg)
                        
                        if on_status:
                            on_status(status_msg, self.planning_steps)
                        
                        if self.debug:
                            print(f"Status: {status_msg}")
                
                elif current_event == 'response.thinking.delta':
                    if 'text' in json_data:
                        text = json_data['text']
                        text = text.replace('<thinking>', '').replace('</thinking>', '')
                        current_thinking += text
                
                elif current_event == 'response.thinking':
                    if 'text' in json_data:
                        text = json_data['text']
                        match = re.search(r'<thinking>(.*?)</thinking>', text, re.DOTALL)
                        if match:
                            thinking = match.group(1).strip()
                            if thinking:
                                self.thinking_content.append(thinking)
                                response.thinking_content.append(thinking)
                    
                    if current_thinking.strip():
                        self.thinking_content.append(current_thinking.strip())
                        response.thinking_content.append(current_thinking.strip())
                        current_thinking = ""
                
                elif current_event == 'response.text.delta':
                    if 'text' in json_data:
                        accumulated_text += json_data['text']
                
                elif current_event == 'response.tool_result':
                    self._process_tool_result(json_data, response)
                
                elif json_data.get('object') == 'message.delta':
                    self._process_message_delta(json_data, response)
            
            response.text = accumulated_text.strip()
            response.sql_queries = self.sql_queries
            response.verified_query_used = self.verified_query_used
            
            return response
            
        except requests.exceptions.Timeout:
            response.text = "Request timed out. Please try again."
            return response
        except requests.exceptions.RequestException as e:
            response.text = f"Request failed: {str(e)}"
            return response
        except Exception as e:
            response.text = f"Unexpected error: {str(e)}"
            return response
    
    def _process_tool_result(self, json_data: Dict, response: AgentResponse):
        """Process tool result events to extract SQL and verification info."""
        content = json_data.get('content', [])
        
        for item in content:
            if not isinstance(item, dict):
                continue
            
            if 'json' in item:
                json_content = item['json']
                
                if 'sql' in json_content:
                    sql = json_content['sql']
                    if sql and sql not in self.sql_queries:
                        self.sql_queries.append(sql)
                
                if json_content.get('verified_query_used'):
                    self.verified_query_used = True
                if json_content.get('query_verified'):
                    self.verified_query_used = True
            
            if 'text' in item:
                text = item['text']
                if 'verified' in text.lower():
                    self.verified_query_used = True
    
    def _process_message_delta(self, json_data: Dict, response: AgentResponse):
        """Process message delta events."""
        delta = json_data.get('delta', {})
        content = delta.get('content', [])
        
        for item in content:
            if item.get('type') == 'tool_result':
                tool_result = item.get('tool_result', {})
                for result_item in tool_result.get('content', []):
                    if 'json' in result_item:
                        json_content = result_item['json']
                        if 'sql' in json_content:
                            sql = json_content['sql']
                            if sql and sql not in self.sql_queries:
                                self.sql_queries.append(sql)
    
    def _execute_sql(self, sql: str) -> Optional[pd.DataFrame]:
        """Execute SQL query and return results as DataFrame."""
        if not self.connection:
            return None
        
        try:
            sql = sql.strip()
            if sql.endswith(';'):
                sql = sql[:-1]
            
            cursor = self.connection.cursor()
            cursor.execute(sql)
            
            columns = [desc[0] for desc in cursor.description] if cursor.description else []
            rows = cursor.fetchall()
            cursor.close()
            
            if rows and columns:
                return pd.DataFrame(rows, columns=columns)
            return None
            
        except Exception as e:
            if self.debug:
                print(f"SQL execution error: {e}")
            return None


class SimpleResponseParser:
    """Simple parser for extracting key info from Cortex responses."""
    
    @staticmethod
    def extract_sql_from_text(text: str) -> List[str]:
        """Extract SQL queries from response text."""
        queries = []
        
        patterns = [
            r'```sql\s*(.*?)\s*```',
            r'```\s*(SELECT.*?)\s*```',
        ]
        
        for pattern in patterns:
            matches = re.findall(pattern, text, re.DOTALL | re.IGNORECASE)
            queries.extend(matches)
        
        return [q.strip() for q in queries if q.strip()]
    
    @staticmethod
    def extract_citations(text: str) -> str:
        """Extract citation information from response."""
        citation_patterns = [
            r'\[Source:?\s*(.*?)\]',
            r'According to (.*?)[,\.]',
            r'From (.*?\.pdf)',
        ]
        
        citations = []
        for pattern in citation_patterns:
            matches = re.findall(pattern, text, re.IGNORECASE)
            citations.extend(matches)
        
        return '; '.join(set(citations)) if citations else ""


if __name__ == "__main__":
    from dotenv import load_dotenv
    load_dotenv()
    
    agent = CortexAgent(
        agent_url=os.getenv("AGENT_ENDPOINT"),
        pat=os.getenv("PAT"),
        debug=True
    )
    
    def status_callback(status, steps):
        print(f"  -> {status} ({len(steps)} steps)")
    
    print("\nTesting Cortex Agent...\n")
    
    response = agent.chat(
        "How many tickets by service type?",
        on_status=status_callback
    )
    
    print("\n" + "="*60)
    print("RESPONSE:")
    print("="*60)
    print(response.get('text', 'No text'))
    
    if response.get('sql_queries'):
        print("\nSQL Queries:")
        for sql in response['sql_queries']:
            print(f"  {sql[:100]}...")
    
    if response.get('verified_query_used'):
        print("\nVerified Query Used!")
    
    print("\nTest complete!")
