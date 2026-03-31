1️⃣ Open Terminal (PowerShell / CMD)


2️⃣ Navigate to the project folder


cd travelethic

3️⃣ Go to backend folder

cd backend

4️⃣ Create a Virtual Environment

python -m venv venv

5️⃣ Activate the Virtual Environment

venv\Scripts\activate

If activation fails, try:

.\venv\Scripts\activate

6️⃣ Install Required Dependencies

pip install -r requirements.txt

Wait until all packages are installed.

7️⃣ Start the FastAPI Backend Server

uvicorn main:app --reload

🎉 Backend is now running!

Server will start at:

http://127.0.0.1:8000

And interactive API docs available here:

http://127.0.0.1:8000/docs
























1️⃣ Open a New Terminal

(Keep the backend terminal running)

2️⃣ Navigate to project root

cd travelethic

3️⃣ Go to the client folder

cd client

4️⃣ Install all dependencies

npm install

This will install all required packages.

5️⃣ Setup the .env file

(We will provide the .env values separately)

Create a new file:

client/.env

Add the environment variables inside it.

6️⃣ Start the Frontend Development Server

npm run dev

🎉 Frontend is Running!

Open your browser and go to:

http://localhost:3000