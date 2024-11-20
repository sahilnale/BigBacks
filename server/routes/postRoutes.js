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
router.post('/upload/:userId', upload.single('image'), async (req, res) => {

    try {
        // Finding the user
        const user = await User.findById(req.params.userId);
        if (!user) return res.status(404).json({ message: 'User not found' });

        // Generate a unique filename for the image using the uuidv4
        const imageKey = `posts/${uuidv4()}_${req.file.originalname}`;

        const uploadParams = {
            Bucket: process.env.S3_BUCKET_NAME,
            Key: imageKey,
            Body: req.file.buffer,
            ContentType: req.file.mimetype,
        };
        
        await s3.send(new PutObjectCommand(uploadParams));
        const newPost = new Post({
            imageUrl: `https://${process.env.S3_BUCKET_NAME}.s3.amazonaws.com/${imageKey}`,
            timestamp: Date.now(),
            review: req.body.review,
            location: req.body.location,
            restaurantName: req.body.restaurantName,
            userId: req.params.userId,
        });

        await newPost.save();

        user.posts.push(newPost);
        await user.save();

        res.status(201).json({ message: 'Post created and added to user successfully', post: newPost });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Error uploading image and creating post' });
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


export default router;
