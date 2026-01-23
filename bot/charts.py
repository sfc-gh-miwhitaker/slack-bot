"""
Chart Generator for Cortex Agent + Slack
Automatically generates appropriate visualizations based on data and query context.
Supports: bar charts, line charts, pie charts, horizontal bars.
"""

import os
import re
import tempfile
import uuid
from typing import Dict, List, Optional, Any
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib
matplotlib.use('Agg')

plt.style.use('seaborn-v0_8-whitegrid')

SNOWFLAKE_BLUE = '#29B5E8'
SNOWFLAKE_DARK = '#1B3A4B'
SNOWFLAKE_COLORS = ['#29B5E8', '#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4', '#FFEAA7', '#DDA0DD', '#98D8C8']


class ChartGenerator:
    """Generates charts from query results."""
    
    def __init__(self, output_dir: str = None):
        self.output_dir = output_dir or tempfile.gettempdir()
        
    def analyze_and_generate(
        self, 
        data: pd.DataFrame, 
        question: str, 
        sql_queries: List[str] = None
    ) -> Optional[Dict[str, Any]]:
        """
        Analyze data and question to generate the most appropriate chart.
        
        Returns:
            Dict with 'path', 'type', 'title' or None if no chart appropriate
        """
        if data is None or data.empty or len(data.columns) < 2:
            return None
        
        if len(data) > 50:
            return None
        
        chart_type = self._determine_chart_type(data, question, sql_queries)
        
        if not chart_type:
            return None
        
        title = self._generate_title(data, question)
        
        generators = {
            'bar': self._generate_bar_chart,
            'horizontal_bar': self._generate_horizontal_bar_chart,
            'pie': self._generate_pie_chart,
            'line': self._generate_line_chart,
        }
        
        generator = generators.get(chart_type)
        if generator:
            path = generator(data, title)
            if path:
                return {
                    'path': path,
                    'type': chart_type,
                    'title': title
                }
        
        return None
    
    def _determine_chart_type(
        self, 
        data: pd.DataFrame, 
        question: str, 
        sql_queries: List[str] = None
    ) -> Optional[str]:
        """Determine the best chart type based on data structure and question."""
        question_lower = question.lower()
        
        keywords_pie = ['breakdown', 'distribution', 'proportion', 'percentage', 'share']
        keywords_bar = ['compare', 'comparison', 'by', 'per', 'each', 'count', 'how many']
        keywords_line = ['trend', 'over time', 'growth', 'change', 'history', 'monthly', 'daily', 'weekly']
        
        if any(kw in question_lower for kw in keywords_line):
            date_cols = [c for c in data.columns if any(d in c.lower() for d in ['date', 'month', 'year', 'time', 'day'])]
            if date_cols:
                return 'line'
        
        numeric_cols = data.select_dtypes(include=['number']).columns.tolist()
        categorical_cols = data.select_dtypes(include=['object', 'category']).columns.tolist()
        
        if len(data) <= 6 and len(numeric_cols) == 1 and len(categorical_cols) == 1:
            if any(kw in question_lower for kw in keywords_pie):
                return 'pie'
            return 'bar'
        
        if len(data) > 6 and len(data) <= 20 and len(numeric_cols) >= 1 and len(categorical_cols) >= 1:
            return 'horizontal_bar'
        
        if len(numeric_cols) >= 1 and len(categorical_cols) >= 1:
            return 'bar'
        
        return None
    
    def _generate_title(self, data: pd.DataFrame, question: str) -> str:
        """Generate a chart title from the question."""
        question = re.sub(r'^(can you |please |show me |what is |what are )', '', question.lower())
        question = re.sub(r'\?$', '', question)
        
        title = question[:50].title()
        if len(question) > 50:
            title += '...'
        
        return title
    
    def _get_output_path(self, chart_type: str) -> str:
        """Generate unique output path for chart."""
        filename = f"chart_{chart_type}_{uuid.uuid4().hex[:8]}.png"
        return os.path.join(self.output_dir, filename)
    
    def _generate_bar_chart(self, data: pd.DataFrame, title: str) -> Optional[str]:
        """Generate a vertical bar chart."""
        try:
            numeric_cols = data.select_dtypes(include=['number']).columns.tolist()
            categorical_cols = data.select_dtypes(include=['object', 'category']).columns.tolist()
            
            if not numeric_cols or not categorical_cols:
                return None
            
            x_col = categorical_cols[0]
            y_col = numeric_cols[0]
            
            fig, ax = plt.subplots(figsize=(10, 6))
            
            bars = ax.bar(
                data[x_col].astype(str), 
                data[y_col],
                color=SNOWFLAKE_COLORS[:len(data)],
                edgecolor='white',
                linewidth=1.5
            )
            
            for bar, value in zip(bars, data[y_col]):
                height = bar.get_height()
                ax.annotate(
                    f'{value:,.0f}' if isinstance(value, (int, float)) else str(value),
                    xy=(bar.get_x() + bar.get_width() / 2, height),
                    xytext=(0, 5),
                    textcoords="offset points",
                    ha='center', 
                    va='bottom',
                    fontsize=11,
                    fontweight='bold',
                    color=SNOWFLAKE_DARK
                )
            
            ax.set_xlabel(x_col.replace('_', ' ').title(), fontsize=12, fontweight='bold')
            ax.set_ylabel(y_col.replace('_', ' ').title(), fontsize=12, fontweight='bold')
            ax.set_title(title, fontsize=14, fontweight='bold', color=SNOWFLAKE_DARK, pad=20)
            
            plt.xticks(rotation=45, ha='right')
            ax.spines['top'].set_visible(False)
            ax.spines['right'].set_visible(False)
            
            plt.tight_layout()
            
            path = self._get_output_path('bar')
            plt.savefig(path, dpi=150, bbox_inches='tight', facecolor='white')
            plt.close()
            
            return path
            
        except Exception as e:
            print(f"Bar chart error: {e}")
            plt.close()
            return None
    
    def _generate_horizontal_bar_chart(self, data: pd.DataFrame, title: str) -> Optional[str]:
        """Generate a horizontal bar chart (good for many categories)."""
        try:
            numeric_cols = data.select_dtypes(include=['number']).columns.tolist()
            categorical_cols = data.select_dtypes(include=['object', 'category']).columns.tolist()
            
            if not numeric_cols or not categorical_cols:
                return None
            
            x_col = categorical_cols[0]
            y_col = numeric_cols[0]
            
            sorted_data = data.sort_values(by=y_col, ascending=True)
            
            fig, ax = plt.subplots(figsize=(10, max(6, len(data) * 0.4)))
            
            bars = ax.barh(
                sorted_data[x_col].astype(str),
                sorted_data[y_col],
                color=SNOWFLAKE_BLUE,
                edgecolor='white',
                linewidth=1
            )
            
            for bar, value in zip(bars, sorted_data[y_col]):
                width = bar.get_width()
                ax.annotate(
                    f'{value:,.0f}' if isinstance(value, (int, float)) else str(value),
                    xy=(width, bar.get_y() + bar.get_height() / 2),
                    xytext=(5, 0),
                    textcoords="offset points",
                    ha='left',
                    va='center',
                    fontsize=10,
                    color=SNOWFLAKE_DARK
                )
            
            ax.set_xlabel(y_col.replace('_', ' ').title(), fontsize=12, fontweight='bold')
            ax.set_ylabel(x_col.replace('_', ' ').title(), fontsize=12, fontweight='bold')
            ax.set_title(title, fontsize=14, fontweight='bold', color=SNOWFLAKE_DARK, pad=20)
            
            ax.spines['top'].set_visible(False)
            ax.spines['right'].set_visible(False)
            
            plt.tight_layout()
            
            path = self._get_output_path('hbar')
            plt.savefig(path, dpi=150, bbox_inches='tight', facecolor='white')
            plt.close()
            
            return path
            
        except Exception as e:
            print(f"Horizontal bar chart error: {e}")
            plt.close()
            return None
    
    def _generate_pie_chart(self, data: pd.DataFrame, title: str) -> Optional[str]:
        """Generate a pie chart for distribution/breakdown questions."""
        try:
            numeric_cols = data.select_dtypes(include=['number']).columns.tolist()
            categorical_cols = data.select_dtypes(include=['object', 'category']).columns.tolist()
            
            if not numeric_cols or not categorical_cols:
                return None
            
            label_col = categorical_cols[0]
            value_col = numeric_cols[0]
            
            fig, ax = plt.subplots(figsize=(10, 8))
            
            colors = SNOWFLAKE_COLORS[:len(data)]
            
            wedges, texts, autotexts = ax.pie(
                data[value_col],
                labels=data[label_col],
                autopct=lambda pct: f'{pct:.1f}%\n({int(pct/100*sum(data[value_col])):,})',
                colors=colors,
                explode=[0.02] * len(data),
                shadow=False,
                startangle=90,
                textprops={'fontsize': 11}
            )
            
            for autotext in autotexts:
                autotext.set_color('white')
                autotext.set_fontweight('bold')
            
            ax.set_title(title, fontsize=14, fontweight='bold', color=SNOWFLAKE_DARK, pad=20)
            
            ax.legend(
                wedges, 
                [f"{label}: {value:,.0f}" for label, value in zip(data[label_col], data[value_col])],
                title=label_col.replace('_', ' ').title(),
                loc="center left",
                bbox_to_anchor=(1, 0, 0.5, 1)
            )
            
            plt.tight_layout()
            
            path = self._get_output_path('pie')
            plt.savefig(path, dpi=150, bbox_inches='tight', facecolor='white')
            plt.close()
            
            return path
            
        except Exception as e:
            print(f"Pie chart error: {e}")
            plt.close()
            return None
    
    def _generate_line_chart(self, data: pd.DataFrame, title: str) -> Optional[str]:
        """Generate a line chart for time-series data."""
        try:
            numeric_cols = data.select_dtypes(include=['number']).columns.tolist()
            
            date_cols = [c for c in data.columns if any(d in c.lower() for d in ['date', 'month', 'year', 'time', 'day'])]
            if not date_cols:
                categorical_cols = data.select_dtypes(include=['object', 'category']).columns.tolist()
                date_cols = categorical_cols[:1] if categorical_cols else []
            
            if not numeric_cols or not date_cols:
                return None
            
            x_col = date_cols[0]
            y_col = numeric_cols[0]
            
            fig, ax = plt.subplots(figsize=(12, 6))
            
            ax.plot(
                data[x_col].astype(str),
                data[y_col],
                color=SNOWFLAKE_BLUE,
                linewidth=2.5,
                marker='o',
                markersize=8,
                markerfacecolor='white',
                markeredgecolor=SNOWFLAKE_BLUE,
                markeredgewidth=2
            )
            
            ax.fill_between(
                range(len(data)),
                data[y_col],
                alpha=0.1,
                color=SNOWFLAKE_BLUE
            )
            
            for i, (x, y) in enumerate(zip(data[x_col], data[y_col])):
                ax.annotate(
                    f'{y:,.0f}' if isinstance(y, (int, float)) else str(y),
                    xy=(i, y),
                    xytext=(0, 10),
                    textcoords="offset points",
                    ha='center',
                    fontsize=9,
                    color=SNOWFLAKE_DARK
                )
            
            ax.set_xlabel(x_col.replace('_', ' ').title(), fontsize=12, fontweight='bold')
            ax.set_ylabel(y_col.replace('_', ' ').title(), fontsize=12, fontweight='bold')
            ax.set_title(title, fontsize=14, fontweight='bold', color=SNOWFLAKE_DARK, pad=20)
            
            plt.xticks(rotation=45, ha='right')
            ax.spines['top'].set_visible(False)
            ax.spines['right'].set_visible(False)
            
            ax.grid(True, alpha=0.3)
            
            plt.tight_layout()
            
            path = self._get_output_path('line')
            plt.savefig(path, dpi=150, bbox_inches='tight', facecolor='white')
            plt.close()
            
            return path
            
        except Exception as e:
            print(f"Line chart error: {e}")
            plt.close()
            return None


def generate_chart_from_sql_result(
    data: pd.DataFrame,
    question: str,
    sql_queries: List[str] = None,
    output_dir: str = None
) -> Optional[Dict[str, Any]]:
    """
    Convenience function to generate a chart from SQL query results.
    
    Args:
        data: DataFrame with query results
        question: User's original question
        sql_queries: List of SQL queries used (optional)
        output_dir: Output directory for chart (optional)
    
    Returns:
        Dict with 'path', 'type', 'title' or None
    """
    generator = ChartGenerator(output_dir)
    return generator.analyze_and_generate(data, question, sql_queries)


if __name__ == "__main__":
    test_data = pd.DataFrame({
        'service_type': ['Cellular', 'Business Internet', 'Home Internet'],
        'ticket_count': [114, 35, 51]
    })
    
    generator = ChartGenerator()
    
    result = generator.analyze_and_generate(
        test_data,
        "Show me a breakdown of tickets by service type"
    )
    
    if result:
        print(f"Generated {result['type']} chart: {result['path']}")
        print(f"Title: {result['title']}")
    else:
        print("No chart generated")
