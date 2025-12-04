const express = require('express');
const path = require('path');
const app = express();
const port = process.env.PORT || 80;

// Serve static files
app.use(express.static('public'));

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ 
    status: 'healthy', 
    timestamp: new Date().toISOString(),
    service: 'wild-rydes'
  });
});

// Main route
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// API endpoint for ride requests
app.get('/api/rides', (req, res) => {
  res.json({
    rides: [
      { id: 1, unicorn: 'Shadowfax', location: 'Seattle' },
      { id: 2, unicorn: 'Bucephalus', location: 'Portland' },
      { id: 3, unicorn: 'Rocinante', location: 'San Francisco' }
    ]
  });
});

app.listen(port, () => {
  console.log(`Wild Rydes server listening on port ${port}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM signal received: closing HTTP server');
  server.close(() => {
    console.log('HTTP server closed');
  });
});
