const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const app = express();

// Basic Setup
app.use(cors());
app.use(bodyParser.urlencoded({ extended: false }));
app.use(bodyParser.json());

// Serve the index.html file when accessing the root path
app.get('/', (req, res) => {
  res.sendFile(__dirname + '/views/index.html');  // Ensure the correct path to your index.html file
});

// In-memory "database" (arrays to store users and exercises)
let users = [];
let exercises = [];

// Routes

// Create a new user
app.post('/api/users', (req, res) => {
  const { username } = req.body;
  if (!username) {
    return res.status(400).json({ error: 'Username is required.' });
  }

  const newUser = { username, _id: new Date().getTime().toString() };
  users.push(newUser);

  res.json(newUser);
});

// Get all users
app.get('/api/users', (req, res) => {
  // Ensure the response only contains `username` and `_id`
  const userList = users.map(user => ({
    username: user.username,
    _id: String(user._id) // Ensure _id is returned as a string
  }));
  
  res.json(userList);
});

// Add exercise for a user
app.post('/api/users/:id/exercises', (req, res) => {
  const { id } = req.params;
  const { description, duration, date } = req.body;

  // Find the user by ID
  const user = users.find(u => u._id == id);
  if (!user) {
    return res.status(404).json({ error: 'User not found.' });
  }

  // Ensure required fields are provided
  if (!description || !duration) {
    return res.status(400).json({ error: 'Description and duration are required.' });
  }

  // Create a new exercise
  const newExercise = {
    userId: id,
    description,
    duration: Number(duration),  // Ensure duration is a number
    date: date ? new Date(date) : new Date()  // Use provided date or today
  };
  exercises.push(newExercise);

  // Respond with the new exercise
  res.json({
    username: user.username,  // User's username
    _id: String(user._id),    // User's _id as a string
    description: newExercise.description,
    duration: newExercise.duration,
    date: newExercise.date.toDateString()  // Exercise date formatted
  });
});

// Get exercises for a user
app.get('/api/users/:id/logs', (req, res) => {
  const { id } = req.params;
  const { from, to, limit } = req.query;

  // Find the user by ID
  const user = users.find(u => u._id == id);
  if (!user) {
    return res.status(404).json({ error: 'User not found.' });
  }

  // Filter exercises for the user
  let userExercises = exercises.filter(exercise => exercise.userId == id);

  // Apply date range filter
  if (from) {
    userExercises = userExercises.filter(exercise => new Date(exercise.date) >= new Date(from));
  }
  if (to) {
    userExercises = userExercises.filter(exercise => new Date(exercise.date) <= new Date(to));
  }

  // Apply limit
  if (limit) {
    userExercises = userExercises.slice(0, Number(limit));
  }

  // Respond with the user's exercise log
  res.json({
    username: user.username,      // User's username
    _id: String(user._id),        // User's _id as a string
    count: userExercises.length,  // Number of exercises
    log: userExercises.map(exercise => ({
      description: exercise.description, 
      duration: Number(exercise.duration), // Ensure duration is a number
      date: exercise.date.toDateString()   // Exercise date formatted
    }))
  });
});

// Start the server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
