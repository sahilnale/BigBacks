import express from 'express';
import multer from 'multer';
import { S3Client, PutObjectCommand, DeleteObjectCommand } from '@aws-sdk/client-s3';
import {Post, User} from '../mongodb/models/User.js';
import dotenv from 'dotenv';
import { v4 as uuidv4 } from 'uuid';
import mongoose from 'mongoose';

dotenv.config();

const router = express.Router();

const s3 = new S3Client({
    region: process.env.AWS_REGION,
    credentials: {
        accessKeyId: process.env.AWS_ACCESS_KEY_ID,
        secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY
    }
});

// this is just for uplaoding the images themselves
const storage = multer.memoryStorage();
const upload = multer({ storage: storage });

// Route to upload a post image to S3, create a new post in MongoDB, and add it to the user's posts
router.post('/upload/:userId', async (req, res) => {
    try {
        // Extracting the user ID from the URL parameter
        const userId = req.params.userId.trim();

        // Finding the user
        const user = await User.findById(userId);
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        // Validate required fields
        const { imageUrl, review, location, restaurantName } = req.body;
        if (!imageUrl || !review || !location || !restaurantName) {
            return res.status(400).json({ message: 'Missing required fields.' });
        }

        // Create a new Post document
        const newPost = new Post({
            imageUrl, // Image URL is directly provided in the request body
            timestamp: Date.now(),
            review,
            location,
            restaurantName,
            userId,
        });

        // Save the new post
        await newPost.save();
        

        // Associate the post with the user
        user.posts.push(newPost._id);
        await user.save();

        res.status(201).json({
            message: 'Post created and added to user successfully',
            post: newPost,
        });
        
        res.json("works");
    } catch (error) {
        console.log("error")
        res.status(500).json({ message: 'Error creating post' });
    }
});
// Route to retrieve all posts
router.get('/', async (req, res) => {
    try {
        const posts = await Post.find();
        res.json(posts);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// Route to retrieve a specific post by ID
router.get('/:id', async (req, res) => {
    try {
        const post = await Post.findById(req.params.id);
        if (!post) return res.status(404).json({ message: 'Post not found' });
        res.json(post);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

//deleting a specific post
router.delete('/:id', async(req, res) => {
    try {
        const post = await Post.findByIdAndDelete(req.params.id);
        const imageUrl = post.imageUrl;
        const imageKey = imageUrl.split('.com/')[1]; //gets the key of the post to delete it on s3
        const deleteParams = {
            Bucket: process.env.S3_BUCKET_NAME,
            Key: imageKey,
        };
        await s3.send(new DeleteObjectCommand(deleteParams));
        if(!post) return res.status(404).json({message: 'Post not found'});
        res.json("Post deleted");
    }
    catch (error) {
        req.status(500).json({message: error.message});
    }
});


// Like a post
router.post('/:postId/like/:userId', async (req, res) => {
    const { postId, userId } = req.params;

    // Ensure userId is a valid ObjectId
    if (!mongoose.Types.ObjectId.isValid(userId)) {
        return res.status(400).send('Invalid userId');
    }

    try {
        const post = await Post.findById(postId);
        if (!post) return res.status(404).send('Post not found');

        // Convert userId to ObjectId to store in Mongoose array (use 'new' keyword)
        const userObjectId = new mongoose.Types.ObjectId(userId);  // <-- Add 'new' here
        let liked = false;

        if (post.likedBy.includes(userObjectId)) {
            // If the user already liked the post, remove the like
            post.likedBy.pull(userObjectId);  // Removes the userId from the likedBy array
            post.likes--;  // Decrement the like count
        } else {
            // Otherwise, add the like
            post.likedBy.push(userObjectId);
            post.likes++; // Increment the like count
            liked = true;
        }

        // Save the updated post
        await post.save();

        // Populate likedBy with user details (assuming you want user info like name, email)
        const updatedPost = await Post.findById(postId).populate('likedBy', 'name email'); // Adjust the fields as per your User schema

        // Return the updated number of likes, liked status, and the user who liked the post
        res.status(200).send({
            likesCount: updatedPost.likes,
            liked,
            likedBy: updatedPost.likedBy // Return the liked user details
        });
    } catch (err) {
        res.status(500).send({ error: err.message });
    }
});


// Route to get all users who liked a post
router.get('/:postId/liked-users', async (req, res) => {
    const { postId } = req.params;

    try {
        const post = await Post.findById(postId).populate('likedBy'); // Adjust fields as per your User schema
        if (!post) return res.status(404).json({ message: 'Post not found' });

        res.status(200).json({
            likedUsers: post.likedBy,
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Error retrieving liked users' });
    }
});

// Add a comment to a post
router.post('/:postId/comments', async (req, res) => {
    const { postId } = req.params;
    const { userId, text } = req.body;

    if (!text) return res.status(400).json({ message: 'Comment text is required' });

    try {
        const post = await Post.findById(postId);
        if (!post) return res.status(404).json({ message: 'Post not found' });

        // Create a new comment object with a generated commentId
        const comment = {
            commentId: new mongoose.Types.ObjectId(), // Auto-generates a new ObjectId
            userId: new mongoose.Types.ObjectId(userId), // Converts string userId to ObjectId
            text,
            timestamp: Date.now(),
        };

        post.comments.push(comment); // Add the comment to the post's comments array
        await post.save(); // Save the updated post

        res.status(201).json({ message: 'Comment added', comment });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});


// Delete a comment
router.delete('/:postId/comments/:commentId', async (req, res) => {
    const { postId, commentId } = req.params;

    try {
        const post = await Post.findById(postId);
        if (!post) return res.status(404).json({ message: 'Post not found' });

        // Find the index of the comment
        const commentIndex = post.comments.findIndex(
            (comment) => comment.commentId.toString() === commentId
        );

        if (commentIndex === -1) return res.status(404).json({ message: 'Comment not found' });

        // Remove the comment from the array
        post.comments.splice(commentIndex, 1);
        await post.save();

        res.status(200).json({ message: 'Comment deleted' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// Reply to a comment
router.post('/:postId/comments/:commentId/replies', async (req, res) => {
    const { postId, commentId } = req.params;
    const { userId, text } = req.body;

    if (!text) return res.status(400).json({ message: 'Reply text is required' });

    try {
        const post = await Post.findById(postId);
        if (!post) {
            console.error(`Post with ID ${postId} not found.`);
            return res.status(404).json({ message: 'Post not found' });
        }

        // Convert commentId to ObjectId to properly search in the array
        const commentObjectId = new mongoose.Types.ObjectId(commentId);

        // Find the comment by matching commentId explicitly
        const comment = post.comments.find(c => c.commentId.toString() === commentObjectId.toString());
        if (!comment) {
            console.error(`Comment with ID ${commentId} not found in post ${postId}.`);
            console.log('Comments in Post:', post.comments);
            return res.status(404).json({ message: 'Comment not found' });
        }

        // Create the reply
        const reply = {
            userId: new mongoose.Types.ObjectId(userId), // Ensure userId is an ObjectId
            text,
            timestamp: Date.now(),
        };

        comment.replies.push(reply);
        await post.save();

        res.status(201).json({ message: 'Reply added', reply });
    } catch (error) {
        console.error('Error:', error);
        res.status(500).json({ message: error.message });
    }
});

//Frontend Integrations

//Saving the star rating for each post
// router.post('/posts/:id/rating', async (req, res) => {
//     const postId = req.params.id;
//     const { rating } = req.body; // Expecting rating in the body of the request

//     if (rating < 0 || rating > 5) {
//         return res.status(400).json({ error: "Invalid rating, it should be between 0 and 5" });
//     }

//     try {
//         // Find the post by ID and update its starRating
//         const post = await Post.findByIdAndUpdate(
//             postId,
//             { starRating: rating },
//             { new: true } // Return the updated post
//         );

//         if (!post) {
//             return res.status(404).json({ error: "Post not found" });
//         }

//         return res.json(post);
//     } catch (error) {
//         console.error(error);
//         return res.status(500).json({ error: "Failed to update the rating" });
//     }
// });






export default router;
