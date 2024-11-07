import express from 'express';
import * as dotenv from 'dotenv';
import cors from 'cors';

import connectDB from './mongodb/connect.js';
import userRoutes from './routes/userRoutes.js';

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json({limit: '50 mb'}));

app.use('/api/v1/user', userRoutes);

app.get('/', async (req, res)  => {
    res.send('Testing');
})

const startServer = async() => {

    try {
        connectDB(process.env.MONGODB_URL);
        app.listen(8080, () => console.log('Server has started on port'))
    } catch (error){
        console.log(error);
    }
}

startServer();