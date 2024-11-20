import express from 'express';
import * as dotenv from 'dotenv';
import cors from 'cors';

import connectDB from './mongodb/connect.js';
import connectAWS from './s3/connect.js';
import userRoutes from './routes/userRoutes.js';
import postRoutes from './routes/postRoutes.js';

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json({ limit: '50mb' }));

// Routes
app.use('/api/v1/user', userRoutes);
app.use('/api/v1/post', postRoutes);

// Default route
app.get('/', (req, res) => {
    res.send('Hello, HTTP World!');
});

// Start HTTP server
const startServer = async () => {
    try {
        // Connect to databases
        console.log('Connecting to MongoDB...');
        await connectDB(process.env.MONGODB_URL);
        console.log('MongoDB connected successfully.');

        console.log('Connecting to AWS S3...');
        connectAWS();
        console.log('AWS S3 connected successfully.');

        // Start the HTTP server
        const PORT = process.env.PORT || 80; // Default HTTP port
        app.listen(PORT, () => {
            console.log(`HTTP server started on port ${PORT}`);
        });
    } catch (error) {
        console.error('Error starting server:', error.message);
    }
};

startServer();
