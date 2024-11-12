import mongoose from 'mongoose';

const PostSchema = new mongoose.Schema({
  image: { type: String, required: true },
  timestamp: { type: Date, default: Date.now },
  review: { type: String, required: true },
  location: { type: String, required: true },
  restaurantName: { type: String, required: true },
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
});

const User = mongoose.model('User', UserSchema);
const Post = mongoose.model('Post', PostSchema);

export { User, Post };