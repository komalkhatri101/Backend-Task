from flask import Flask, render_template, request, redirect, url_for, session, flash
from flask_sqlalchemy import SQLAlchemy
from datetime import datetime
import os

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = "sqlite:///todo.db"
app.config['SECRET_KEY'] = os.urandom(24)  # Secret key for session management
db = SQLAlchemy(app)

# Define the Todo model class
class Todo(db.Model):
    sno = db.Column(db.Integer, primary_key=True)
    task_name = db.Column(db.String(200), nullable=False)
    Description = db.Column(db.String(500), nullable=False)
    Status = db.Column(db.String(200), nullable=False)
    Priorty = db.Column(db.String(200), nullable=False)
    Time = db.Column(db.Date, default=datetime.utcnow)
    Assigned_user = db.Column(db.String(500), nullable=False)
    
    def __repr__(self):
        return f"{self.sno} - {self.task_name}"

# Login route
@app.route("/login", methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        user_type = request.form['userType']
        username = request.form['username']
        password = request.form['password']
        
        # Fixed credentials as specified
        if user_type == 'admin' and password == 'admin456':
            session['logged_in'] = True
            session['username'] = username
            session['role'] = 'admin'
            return redirect("/")
        elif user_type == 'user' and password == 'user123':
            session['logged_in'] = True
            session['username'] = username
            session['role'] = 'user'
            return redirect("/")
        else:
            return render_template('login.html', error="Invalid credentials")
    
    return render_template('login.html')

# Logout route
@app.route("/logout")
def logout():
    session.pop('logged_in', None)
    session.pop('username', None)
    session.pop('role', None)
    return redirect(url_for('login'))

# Main route - protected by login
@app.route("/", methods=['GET','POST'])
def hello():
    # Check if user is logged in
    if not session.get('logged_in'):
        return redirect(url_for('login'))
    
    if request.method=='POST':
        task_name = request.form['task_name']
        description = request.form['Description']
        status = request.form['Status']
        priority = request.form['Priorty']
        assigned_user = request.form['Assigned_user']
        todo = Todo(
            task_name=task_name,
            Description=description,
            Status=status,
            Priorty=priority,
            Assigned_user=assigned_user
        )
        db.session.add(todo)
        db.session.commit()
    
    # For admin, show all todos. For users, show only assigned todos
    if session.get('role') == 'admin':
        allTodo = Todo.query.all()
    else:
        allTodo = Todo.query.filter_by(Assigned_user=session.get('username')).all()
    
    return render_template('index.html', allTodo=allTodo, 
                          username=session.get('username'), 
                          role=session.get('role'))

# Update route - protected by login
@app.route("/update/<int:sno>", methods=['GET', 'POST'])
def update(sno):
    if not session.get('logged_in'):
        return redirect(url_for('login'))
    
    todo = Todo.query.filter_by(sno=sno).first()
    
    # Check permissions: admin can edit any task, users can only edit their own
    if session.get('role') != 'admin' and todo.Assigned_user != session.get('username'):
        return redirect("/")
    
    if request.method == 'POST':
        todo.task_name = request.form['task_name']
        todo.Description = request.form['Description']
        todo.Status = request.form['Status']
        todo.Priorty = request.form['Priorty']
        todo.Assigned_user = request.form['Assigned_user']
        db.session.commit()
        return redirect("/")
    
    return render_template('update.html', todo=todo)

# Delete route - protected by login and role
@app.route("/delete/<int:sno>")
def delete(sno):
    if not session.get('logged_in'):
        return redirect(url_for('login'))
    
    # Only admins can delete tasks
    if session.get('role') != 'admin':
        return redirect("/")
    
    todo = Todo.query.filter_by(sno=sno).first()
    db.session.delete(todo)
    db.session.commit()
    return redirect("/")

# Create database tables before running the app
with app.app_context():
    db.create_all()

if __name__ == "__main__":
    app.run(debug=True)
