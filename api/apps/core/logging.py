import logging
import json
from datetime import datetime

class JSONFormatter(logging.Formatter):
    """
    Custom JSON formatter for Django logs
    """
    def format(self, record):
        log_data = {
            'timestamp': datetime.now().isoformat(),
            'level': record.levelname,
            'message': record.getMessage(),
            'logger': record.name,
            'path': record.pathname,
            'lineno': record.lineno,
            'func': record.funcName,
        }
        
        # Add exception info if available
        if record.exc_info:
            log_data['exc_info'] = self.formatException(record.exc_info)
        
        # Add extra fields if available
        if hasattr(record, 'extra'):
            log_data.update(record.extra)
        
        return json.dumps(log_data) 