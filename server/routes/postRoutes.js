import express from 'express';
import multer from 'multer';
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';
import {Post, User} from '../mongodb/models/User.js';
import dotenv from 'dotenv';
import { v4 as uuidv4 } from 'uuid';

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

export default router;
