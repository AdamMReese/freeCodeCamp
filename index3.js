require('dotenv').config();
const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const dns = require('dns');
const url = require('url');

const app = express();

// Basic Configuration
const port = process.env.PORT || 3000;

app.use(cors());
app.use(bodyParser.urlencoded({ extended: false }));

app.use('/public', express.static(`${process.cwd()}/public`));

app.get('/', function (req, res) {
  res.sendFile(process.cwd() + '/views/index.html');
});

// Storage for URLs
let urlDatabase = {};
let currentShortUrl = 1;

// POST to create short URL
app.post('/api/shorturl', function (req, res) {
  const originalUrl = req.body.url;

  // Validate the URL
  const parsedUrl = url.parse(originalUrl);
  if (!parsedUrl.protocol || !parsedUrl.host) {
    return res.json({ error: 'invalid url' });
  }

  // Check DNS lookup
  dns.lookup(parsedUrl.host, (err) => {
    if (err) {
      return res.json({ error: 'invalid url' });
    }

    // Store URL and return short URL
    const shortUrl = currentShortUrl++;
    urlDatabase[shortUrl] = originalUrl;
    res.json({ original_url: originalUrl, short_url: shortUrl });
  });
});

// GET to redirect short URL
app.get('/api/shorturl/:short_url', function (req, res) {
  const shortUrl = req.params.short_url;
  const originalUrl = urlDatabase[shortUrl];

  if (!originalUrl) {
    return res.json({ error: 'invalid url' });
  }

  res.redirect(originalUrl);
});

// Listen on the specified port
app.listen(port, function () {
  console.log(`Listening on port ${port}`);
});
