import mongoose from 'mongoose';

const PostSchema = new mongoose.Schema({
  imageUrl: { type: String, required: true },
  timestamp: { type: Date, default: Date.now },
  review: { type: String, required: true },
  location: { type: String, required: true },
  restaurantName: { type: String, required: true },
  likes: {
    type: Number,
    default: 0, // Starts with 0 likes
  },
  starRating: {
    type: Number,
    min: 0,
    max: 5, // Star rating between 0 to 5
    default: 0, // Default no rating
  },
  comments: [
    {
        userId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User', // Reference to the user who made the comment
        },
        text: {
            type: String,
            trim: true,
        },
        timestamp: {
            type: Date,
            default: Date.now,
        },
    },
  ],

});

const UserSchema = new mongoose.Schema({
  name: { type: String, required: true },
  username: {type: String, required: true, unique: true},
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  friends: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  friendRequests: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  pendingRequests: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  posts: [PostSchema],
  profilePicture: { type: String },
  loggedIn: {type: Boolean},
});

const User = mongoose.model('User', UserSchema);
const Post = mongoose.model('Post', PostSchema);

export { User, Post };