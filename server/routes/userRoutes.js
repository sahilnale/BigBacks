import express from 'express';
import * as dotenv from 'dotenv';
import multer from 'multer';
import { v4 as uuidv4 } from 'uuid';
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';
import { User } from '../mongodb/models/User.js';

dotenv.config();

const s3 = new S3Client({
    region: process.env.AWS_REGION,
    credentials: {
        accessKeyId: process.env.AWS_ACCESS_KEY_ID,
        secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY
    }
});

const router = express.Router();
const storage = multer.memoryStorage();
const upload = multer({ storage: storage });

//creates a new user
router.post('/', async (req, res) => {
    try {
        const user = new User(req.body);
        await user.save();
        res.status(201).json(user);
    } catch (error) {
        res.status(400).json({ message: error.message });
    }
});

//Returns all users of find my food
router.get('/', async (req, res) => {
    try {
        const users = await User.find();
        res.json(users);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

//Retrieves a certain user by id
router.get('/:id', async (req, res) => {
    try {
        const user = await User.findById(req.params.id).populate('posts');
        if (!user) return res.status(404).json({ message: 'User not found' });
        res.json(user);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

//This pulls the posts of a specified user
router.post('/:id/posts', async (req, res) => {
    try {
        const user = await User.findById(req.params.id);
        if (!user) return res.status(404).json({ message: 'User not found' });

        user.posts.push(req.body);
        await user.save();
        res.status(201).json(user);
    } catch (error) {
        res.status(400).json({ message: error.message });
    }
});

//This is for removing users from the database, if they wanna delete their account
router.delete('/:id', async (req, res) => {
    try {
        const user = await User.findByIdAndDelete(req.params.id);
        if (!user) return res.status(404).json({ message: 'User not found' });
        res.json({ message: 'User deleted' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

//The first input "id" is the receiver, the second input "friendId" is the sender
//Sender = friend
//Receiver = user
//Sender sends friend request to receiver. This adds sender to receivers friend requests and receiver to senders pending requests
router.post('/:id/friendRequest/:friendId', async (req, res) => {
    try {
        const { id, friendId } = req.params;
        //friendId will the the person who sent the requests
        const user = await User.findById(id);
        const friend = await User.findById(friendId);

        //We need to ensure that both friend and curr user are valid
        if (!user || !friend) return res.status(404).json({ message: 'User not found' });

        //check if they are already in the friendrequest
        if (!user.friendRequests.includes(friendId) && !friend.pendingRequests.includes(id)) {
            user.friendRequests.push(friendId);
            friend.pendingRequests.push(id);
            await user.save();
            await friend.save();
        }


        if(friendId)

        res.status(200).json({ message: 'Friend request sent', user });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

//The first input "id" is the receiver, the second input "friendId" is the sender
//Sender = friend
//Receiver = user
//Receiver approves friend request: moves Sender from user's request to friends and moves user from sender's pending to friends
router.post('/:id/acceptFriend/:friendId', async (req, res) => {
    try {
        const { id, friendId } = req.params;

        const user = await User.findById(id);
        const friend = await User.findById(friendId);

        if (!user || !friend) return res.status(404).json({ message: 'User not found' });
        //First step is to ensure that the friend request was sent or exists
        if (user.friendRequests.includes(friendId)) {
            user.friendRequests = user.friendRequests.filter(reqId => reqId.toString() !== friendId);//Moves this person from the friendrequests to friends
            user.friends.push(friendId);
            await user.save();

            //if the person who just accepted the friend request is not already on the other persons friends list, it adds them now
            if (!friend.friends.includes(id)) {
                //Remove them from pending requests
                friend.pendingRequests = friend.pendingRequests.filter(reqId => reqId.toString() !== id);
                friend.friends.push(id);
                await friend.save();
            }

            res.status(200).json({ message: 'Friend request accepted', user });
        } else {
            res.status(400).json({ message: 'Friend request not found' });
        }
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

router.post('/:id/profile-pic', upload.single('image'), async (req, res) => {
    try {
        const user = await User.findById(req.params.id);
        if (!user) return res.status(404).json({ message: 'User not found' });

        // Generate a unique filename for the profile picture
        const imageKey = `profile_pics/${uuidv4()}_${req.file.originalname}`;

        const uploadParams = {
            Bucket: process.env.S3_BUCKET_NAME,
            Key: imageKey,
            Body: req.file.buffer,
            ContentType: req.file.mimetype,
        };

        // Upload image to S3
        await s3.send(new PutObjectCommand(uploadParams));

        // Update the user's profile picture URL in MongoDB
        user.profilePicture = `https://${process.env.S3_BUCKET_NAME}.s3.amazonaws.com/${imageKey}`;
        await user.save();

        res.status(200).json({ message: 'Profile picture uploaded successfully', profilePicUrl: user.profilePicUrl });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Error uploading profile picture' });
    }
});

export default router;