// index.js
// where your node app starts

// Import required modules
var express = require('express');
var cors = require('cors');
var app = express();

// Enable CORS so that the API is remotely testable by FCC
app.use(cors({ optionsSuccessStatus: 200 }));  // Legacy browsers choke on 204

// Serve static files from the "public" directory
app.use(express.static('public'));

// Route for the homepage
app.get("/", function (req, res) {
  res.sendFile(__dirname + '/views/index.html');
});

// Helper function to check for invalid dates
const isInvalidDate = (date) => date.toUTCString() === "Invalid Date";

// Timestamp API endpoint for parsing date or returning current date
app.get("/api/:date?", function (req, res) {
  let { date } = req.params;

  let parsedDate;

  // Case when no date is provided (current date)
  if (!date) {
    parsedDate = new Date();
  } else {
    // Check if the input is a Unix timestamp (numeric string)
    if (/^\d+$/.test(date)) {
      parsedDate = new Date(parseInt(date, 10));
    } else {
      // Otherwise, treat it as a standard date string
      parsedDate = new Date(date);
    }
  }

  // If the date is invalid, return an error message
  if (isInvalidDate(parsedDate)) {
    return res.json({ error: "Invalid Date" });
  }

  // Return both Unix timestamp and UTC date
  res.json({
    unix: parsedDate.getTime(),
    utc: parsedDate.toUTCString()
  });
});

// Listen for requests
var listener = app.listen(process.env.PORT || 3000, function () {
  console.log('Your app is listening on port ' + listener.address().port);
});
