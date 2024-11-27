import express from 'express';
import * as dotenv from 'dotenv';
import multer from 'multer';
import { v4 as uuidv4 } from 'uuid';
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';
import { User, Post } from '../mongodb/models/User.js';
import bcrypt from 'bcrypt';
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
const emailRegex = /^[^\s@]+@[^\s@]+\.(com|org|net|edu|gov|mil|co|io|info|biz|me|us|ca|uk|in)$/i;

//creates a new user
router.post('/', async (req, res) => {
    try {
        const { name, username, email, password, } = req.body;
        if (!emailRegex.test(email)) {
            return res.status(400).json({ message: 'Invalid email format' });
        }
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(password, salt);
        const user = new User({
            name,
            username,
            email,
            password: hashedPassword,
            loggedIn: false,

        });
        await user.save();
        res.status(201).json(user);
    } catch (error) {
        res.status(400).json({ message: error.message });
    }
});

router.post('/login', async (req, res) => {
    try {
        const { username, password } = req.body;

        const user = await User.findOne({ username });
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        // Compare the provided password with the stored hashed password
        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch) {
            return res.status(400).json({ message: 'Incorrect password' });
        }
        // If successful, respond with user info or a token (for authentication)
        user.loggedIn = true;
        await user.save();
        res.status(200).json({ message: 'Login successful', userId: user._id });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

//Returns all users of find my food
// router.get('/', async (req, res) => {
//     try {
//         const users = await User.find();
//         res.json(users);
//     } catch (error) {
//         res.status(500).json({ message: error.message });
//     }
// });

// Returns all users with their posts including likes count and likedBy
router.get('/', async (req, res) => {
    try {
      const users = await User.find()
        .populate({
          path: 'posts', // Populate the `posts` field in the User schema
          populate: [
            {
              path: 'likedBy', // Populate the `likedBy` field in each post
              model: 'User',
              select: 'name username email', // Customize fields to include from the `User` model
            },
            {
              path: 'comments.userId', // Populate `userId` for comments
              model: 'User',
              select: 'name username email',
            },
            {
              path: 'comments.replies.userId', // Populate `userId` for replies
              model: 'User',
              select: 'name username email',
            },
          ],
        })
        .select() // Include posts and password in the response for debugging
        .lean(); // Use `.lean()` to return plain JavaScript objects
  
      res.status(200).json(users); // Send populated users as response
    } catch (error) {
      console.error('Error fetching users:', error);
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

//Additional routes added 
// Reject a friend request - This works!!
router.post('/:id/rejectFriend/:friendId', async (req, res) => {
    try {
        // Extracting the current user's id and the id of the user who sent the friend request
        const { id, friendId } = req.params;

        // Find the current user and the friend who sent the request in the database
        const user = await User.findById(id);
        const friend = await User.findById(friendId);

        // If either user is not found, return a 404 error
        if (!user || !friend) return res.status(404).json({ message: 'User not found' });

        // Remove the friend's id from the user's friendRequests array
        user.friendRequests = user.friendRequests.filter(reqId => reqId.toString() !== friendId);
        
        // Remove the user's id from the friend's pendingRequests array
        friend.pendingRequests = friend.pendingRequests.filter(reqId => reqId.toString() !== id);

        // Save changes to both user and friend
        await user.save();
        await friend.save();

        // Send success response
        res.status(200).json({ message: 'Friend request rejected' });
    } catch (error) {
        // Handle any errors that occur and send a 500 status with an error message
        res.status(500).json({ message: error.message });
    }
});

// Remove a friend from the friends list - This works!!
router.post('/:id/removeFriend/:friendId', async (req, res) => {
    try {
        // Extracting the ids of the current user and the friend to be removed
        const { id, friendId } = req.params;

        // Find both users in the database
        const user = await User.findById(id);
        const friend = await User.findById(friendId);

        // If either user is not found, return a 404 error
        if (!user || !friend) return res.status(404).json({ message: 'User not found' });

        // Remove the friendId from the user's friends list
        user.friends = user.friends.filter(friendId => friendId.toString() !== friend._id.toString());
        
        // Remove the user's id from the friend's friends list
        friend.friends = friend.friends.filter(friendId => friendId.toString() !== user._id.toString());

        // Save changes to both user and friend
        await user.save();
        await friend.save();

        // Send success response
        res.status(200).json({ message: 'Friend removed successfully' });
    } catch (error) {
        // Handle any errors that occur and send a 500 status with an error message
        res.status(500).json({ message: error.message });
    }
});

// Retrieve all friends of a user - This works!!
router.get('/:id/friends', async (req, res) => {
    try {
        // Find the user by id and populate the friends field to get full friend information
        const user = await User.findById(req.params.id).populate('friends');

        // If the user is not found, return a 404 error
        if (!user) return res.status(404).json({ message: 'User not found' });

        // Return the user's friends as a JSON response
        res.json(user.friends);
    } catch (error) {
        // Handle any errors that occur and send a 500 status with an error message
        res.status(500).json({ message: error.message });
    }
});

// Cancel a sent friend request - This works!!
router.post('/:id/cancelRequest/:friendId', async (req, res) => {
    try {
        // Extracting the ids of the user canceling the request and the user who received it
        const { id, friendId } = req.params;
        
        // Find both users (sender and receiver) in the database
        const sender = await User.findById(id);
        const receiver = await User.findById(friendId);

        // If either user is not found, return a 404 error
        if (!sender || !receiver) return res.status(404).json({ message: 'User not found' });

        // Check if the request exists: friendId should be in sender's pendingRequests,
        // and sender's id should be in receiver's friendRequests
        if (sender.pendingRequests.includes(friendId) && receiver.friendRequests.includes(id)) {
            // Remove the friendId from the sender's pendingRequests list
            sender.pendingRequests = sender.pendingRequests.filter(reqId => reqId.toString() !== friendId);
            
            // Remove the sender's id from the receiver's friendRequests list
            receiver.friendRequests = receiver.friendRequests.filter(reqId => reqId.toString() !== id);

            // Save changes to both sender and receiver
            await sender.save();
            await receiver.save();

            // Send success response
            res.status(200).json({ message: 'Friend request canceled' });
        } else {
            // If no such friend request exists, send a 400 error response
            res.status(400).json({ message: 'Friend request not found' });
        }
    } catch (error) {
        // Handle any errors that occur and send a 500 status with an error message
        res.status(500).json({ message: error.message });
    }
});

//This is for retrieving the user info by username
router.get('/getByUsername/:usName', async (req, res) => {
    try {
        const entry = String(req.params.usName);
        const users = await User.find({ username: { $regex: `^${entry}`, $options: 'i' } });

        // If the user is not found, return a 404 error
        if (users.length === 0) return res.status(404).json({ message: 'No users found' });
        res.json(users);
    } catch (error) {
        // Handle any errors that occur and send a 500 status with an error message
        res.status(500).json({ message: error.message });
    }
});

//This is for returning the feed of the user(latest posts of friends)
router.get('/getFeed/:id', async(req, res) => {
    try {
        const user = await User.findById(req.params.id);
        const friendsList = user.friends;
        let feed = [];
        for (let index = 0; index < friendsList.length; index++) {
            const friend = await User.findById(friendsList[index]).populate('posts');
            if(friend && friend.posts){
                feed = feed.concat(friend.posts);
            }
        }
        feed.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));
        res.json(feed);
    }
    catch(error){
        res.status(500).json({message: error.message});
    }
});

router.get('/getPostDetailsFromFeed/:id', async(req, res) => {
    try {
        const user = await User.findById(req.params.id);
        

        let feed = [];

        const userPosts = await User.findById(user._id).populate({
            path: 'posts', 
            populate: [
                { path: 'likedBy', select: 'name username email' }, 
                {
                    path: 'comments.userId',
                    select: 'name username email',
                },
                {
                    path: 'comments.replies.userId',
                    select: 'name username email',
                }, 
            ],
        });

        
        if (userPosts && userPosts.posts) {
            feed = feed.concat(userPosts.posts);
        }

        
        const friendsList = user.friends;

        for (let index = 0; index < friendsList.length; index++) {
            const friend = await User.findById(friendsList[index]).populate({
                path: 'posts', 
                populate: [
                    { path: 'likedBy', select: 'name username email' },
                    {
                        path: 'comments.userId',
                        select: 'name username email',
                    }, 
                    {
                        path: 'comments.replies.userId',
                        select: 'name username email',
                    }, 
                ],
            });

            if (friend && friend.posts) {
                feed = feed.concat(friend.posts); 
            }
        }

        
        const postDetails = feed.map(post => ({
            postId: post._id,
            likes: post.likedBy.length, 
            review: post.review,
            userId: post.userId,
            imageUrl: post.imageUrl,
            restaurantName: post.restaurantName,
            comments: post.comments,
        }));

        
        res.json(postDetails);
    } catch (error) {
        console.error('Error fetching post details:', error);
        res.status(500).json({ message: error.message });
    }
});





// //This is for getting all the posts of all user's friends
// router.get('/:id/friends/posts', async (req, res) => {
//     try {
//         // Get the user by ID
//         const user = await User.findById(req.params.id)
//             .populate('friends') // Populate the user's friends array
//             .select('friends'); // Only select the friends field

//         if (!user) {
//             return res.status(404).json({ message: 'User not found' });
//         }

//         // Get the friends' posts
//         const friendsPosts = await Post.find({
//             userId: { $in: user.friends }, // Match posts where userId is one of the friends' IDs
//         }).populate('likedBy', 'name username email') // Populate the likedBy field
//           .populate({
//             path: 'comments.userId', // Populate userId in comments
//             model: 'User',
//             select: 'name username email'
//           })
//           .populate({
//             path: 'comments.replies.userId', // Populate userId in replies
//             model: 'User',
//             select: 'name username email'
//           })
//           .lean(); 

        
//         res.status(200).json(friendsPosts);
//     } catch (error) {
//         console.error('Error fetching friends posts:', error);
//         res.status(500).json({ message: error.message });
//     }
// });


export default router;