import express from 'express';
import * as dotenv from 'dotenv';
import cors from 'cors';
import https from 'https';
import fs from 'fs';

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
    res.send('Hello, HTTPS World!');
});

// Load SSL certificate files
const httpsOptions = {
    key: fs.readFileSync('/etc/letsencrypt/live/api.bigbacksapp.com/privkey.pem'),
    cert: fs.readFileSync('/etc/letsencrypt/live/api.bigbacksapp.com/fullchain.pem'),
};

// Start HTTPS server
const startServer = async () => {
    try {
        // Connect to databases
        console.log('Connecting to MongoDB...');
        await connectDB(process.env.MONGODB_URL);
        console.log('MongoDB connected successfully.');

        console.log('Connecting to AWS S3...');
        connectAWS();
        console.log('AWS S3 connected successfully.');

        // Start the HTTPS server
        const HTTPS_PORT = process.env.HTTPS_PORT || 443; // Default HTTPS port
        https.createServer(httpsOptions, app).listen(HTTPS_PORT, () => {
            console.log(`HTTPS server started on port ${HTTPS_PORT}`);
        });

        // Optional: Start HTTP server to redirect to HTTPS
        const HTTP_PORT = process.env.HTTP_PORT || 80; // Default HTTP port
        app.listen(HTTP_PORT, () => {
            console.log(`HTTP server started on port ${HTTP_PORT}`);
            app.use((req, res) => {
                const host = req.headers.host.replace(/:\d+/, `:${HTTPS_PORT}`);
                res.redirect(`https://${host}${req.url}`);
            });
        });
    } catch (error) {
        console.error('Error starting server:', error.message);
    }
};

startServer();