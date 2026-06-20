from flask import Flask, render_template, request, redirect
from sqlalchemy import create_engine, text
import os

app = Flask(__name__)

DB_HOST = os.getenv("DB_HOST")
DB_PORT = os.getenv("DB_PORT", "5432")
DB_NAME = os.getenv("DB_NAME")
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")

DATABASE_URL = (
    f"postgresql://{DB_USER}:{DB_PASSWORD}"
    f"@{DB_HOST}:{DB_PORT}/{DB_NAME}"
)

engine = create_engine(DATABASE_URL)


def initialize_database():
    with engine.connect() as conn:
        conn.execute(text("""
            CREATE TABLE IF NOT EXISTS visitors (
                id SERIAL PRIMARY KEY,
                name VARCHAR(100),
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """))
        conn.commit()


initialize_database()


@app.route("/")
def home():
    with engine.connect() as conn:
        rows = conn.execute(
            text(
                "SELECT id, name, created_at "
                "FROM visitors "
                "ORDER BY id DESC"
            )
        ).fetchall()

    return render_template("index.html", visitors=rows)


@app.route("/add", methods=["POST"])
def add():
    name = request.form.get("name")

    with engine.connect() as conn:
        conn.execute(
            text(
                "INSERT INTO visitors(name) "
                "VALUES (:name)"
            ),
            {"name": name}
        )
        conn.commit()

    return redirect("/")


@app.route("/health")
def health():
    try:
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))

        return {
            "status": "healthy",
            "database": "connected"
        }

    except Exception as e:
        return {
            "status": "unhealthy",
            "database": str(e)
        }, 500


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)