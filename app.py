from flask import Flask, render_template, request, redirect, url_for, session, flash, jsonify
import pymysql
from datetime import datetime, date, timedelta
import os
from werkzeug.utils import secure_filename
from werkzeug.security import check_password_hash, generate_password_hash
from functools import wraps
import uuid
import smtplib
from email.mime.text import MIMEText
import time
import random
import requests

app = Flask(__name__)
app.secret_key = 'your-super-secret-key-here-make-it-long-and-complex'


ZEPTOMAIL_API_URL = "https://api.zeptomail.in/v1.1/email"
ZEPTOMAIL_API_TOKEN = "PHtE6r1fFu65gzMt8UAJ5/7rHsGsN40m+uJufQkRtYxAXKABS01XrNooxGfkq018A/cXF/DPwNpque6ateiAd23lYGpNVGqyqK3sx/VYSPOZsbq6x00ftFsadUXVV4brdtRv0SXXvdrbNA=="  # Replace with your actual token
ZEPTOMAIL_FROM_EMAIL = "contact@rudhisoft.com"
ZEPTOMAIL_FROM_NAME = "Rudhiarch"


# Session configuration
app.config['SESSION_TYPE'] = 'filesystem'
app.config['SESSION_PERMANENT'] = False
app.config['SESSION_USE_SIGNER'] = True
app.config['SESSION_FILE_DIR'] = '/tmp/flask_session'
app.config['SESSION_FILE_THRESHOLD'] = 500
app.config['SESSION_FILE_MODE'] = 384

# Email Configuration (Add after session configuration)


# Set session lifetime
app.permanent_session_lifetime = timedelta(hours=24)

# Database Configuration
def db_connection():
    return pymysql.connect(
        host="localhost",
        user="sam",
        password="Sam@130201",
        database="construction_site_management",
        cursorclass=pymysql.cursors.DictCursor
    )

# Improved role_required decorator
def role_required(required_role):
    def decorator(f):
        @wraps(f)
        def decorated_function(*args, **kwargs):
            # Check if user is logged in
            if 'user_id' not in session or 'role' not in session:
                flash('Please login to access this page.', 'danger')
                return redirect(url_for('login'))
            
            # Check if user has the required role
            if session['role'] != required_role:
                flash('Access denied. Please login with proper credentials.', 'danger')
                return redirect(url_for('login'))
            
            # Check if user is active in database
            try:
                conn = db_connection()
                cursor = conn.cursor()
                cursor.execute("SELECT status FROM register WHERE id = %s", (session['user_id'],))
                user = cursor.fetchone()
                conn.close()
                
                if not user or user['status'] != 'active':
                    session.clear()
                    flash('Your account is not active. Please contact administrator.', 'danger')
                    return redirect(url_for('login'))
            except Exception as e:
                app.logger.error(f"Error checking user status: {str(e)}")
                flash('Database error. Please try again.', 'danger')
                return redirect(url_for('login'))
            
            return f(*args, **kwargs)
        return decorated_function
    return decorator


# OTP Functions
def generate_otp():
    return str(random.randint(100000, 999999))  # Generate 6-digit OTP

def send_otp_email(email, otp):
    """
    Send OTP email using ZeptoMail
    Returns: (success: bool, error_message: str or None)
    """
    try:
        headers = {
            "accept": "application/json",
            "content-type": "application/json",
            "authorization": f"Zoho-enczapikey {ZEPTOMAIL_API_TOKEN}"
        }
        
        payload = {
            "from": {
                "address": ZEPTOMAIL_FROM_EMAIL,
                "name": ZEPTOMAIL_FROM_NAME
            },
            "to": [
                {
                    "email_address": {
                        "address": email
                    }
                }
            ],
            "subject": "Your OTP Code for Verification",
            "htmlbody": f"""
                <html>
                    <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
                        <div style="max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #ddd; border-radius: 10px;">
                            <h2 style="color: #1e3a8a; text-align: center;">OTP Verification</h2>
                            <p>Hello,</p>
                            <p>Your One-Time Password (OTP) for verification is:</p>
                            <div style="text-align: center; margin: 30px 0;">
                                <span style="font-size: 32px; font-weight: bold; color: #1e3a8a; letter-spacing: 5px; padding: 15px 30px; border: 2px dashed #1e3a8a; border-radius: 8px; display: inline-block;">
                                    {otp}
                                </span>
                            </div>
                            <p style="color: #e74c3c; font-weight: bold;">⚠️ This code will expire in 5 minutes.</p>
                            <p>If you didn't request this code, please ignore this email.</p>
                            <hr style="border: none; border-top: 1px solid #ddd; margin: 30px 0;">
                            <p style="font-size: 12px; color: #666;">
                                Best regards,<br>
                                <strong>Rudhiarch Team</strong>
                            </p>
                        </div>
                    </body>
                </html>
            """
        }
        
        response = requests.post(ZEPTOMAIL_API_URL, headers=headers, json=payload, timeout=10)
        
        # Log response for debugging
        print(f"ZeptoMail Status Code: {response.status_code}")
        print(f"ZeptoMail Response: {response.text}")
        
        response.raise_for_status()
        return True, None
        
    except requests.exceptions.Timeout:
        return False, "Email service timeout. Please try again."
    except requests.exceptions.RequestException as e:
        error_msg = f"Failed to send email: {str(e)}"
        if hasattr(e, 'response') and e.response is not None:
            error_msg += f" - {e.response.text}"
        return False, error_msg
    except Exception as e:
        return False, f"Unexpected error: {str(e)}"
    





#######################
# Forgot Password Routes (Super Admin Only)
#######################

@app.route('/forgot_password', methods=['GET', 'POST'])
def forgot_password():
    if request.method == 'POST':
        email = request.form.get('email')
        
        if not email:
            flash('Please enter your email address.', 'danger')
            return redirect(url_for('forgot_password'))
        
        conn = db_connection()
        cursor = conn.cursor()
        try:
            # Check if user exists and is a super_admin
            cursor.execute("SELECT * FROM register WHERE email = %s AND role = 'super_admin'", (email,))
            user = cursor.fetchone()

            if user:
                # Check if user is active
                if user['status'] != 'active':
                    flash('Your account is disabled. Please contact administrator.', 'danger')
                    return redirect(url_for('forgot_password'))
                
                otp = generate_otp()
                success, error = send_otp_email(email, otp)

                if success:
                    session['reset_email'] = email
                    session['reset_otp'] = otp
                    session['reset_otp_expiry'] = (datetime.now() + timedelta(minutes=5)).timestamp()

                    flash('OTP has been sent to your email address.', 'success')
                    return redirect(url_for('verify_reset_otp'))
                else:
                    flash(f"Error sending OTP: {error}", 'danger')
            else:
                flash("No Super Admin account found with this email.", 'danger')
        except Exception as e:
            flash('Database error occurred.', 'danger')
            app.logger.error(f"Error in forgot password: {str(e)}")
        finally:
            conn.close()
    
    return render_template('forgot_password.html')

@app.route('/verify_reset_otp', methods=['GET', 'POST'])
def verify_reset_otp():
    if request.method == 'POST':
        otp_input = request.form.get('otp')
        
        if 'reset_otp' not in session or 'reset_email' not in session:
            flash("Session expired. Please try again.", 'danger')
            return redirect(url_for('forgot_password'))

        if time.time() > session.get('reset_otp_expiry', 0):
            flash("OTP expired. Please request a new one.", 'danger')
            return redirect(url_for('forgot_password'))

        if otp_input == session['reset_otp']:
            flash("OTP verified successfully. Please set a new password.", 'success')
            return redirect(url_for('reset_password'))
        else:
            flash("Invalid OTP. Please try again.", 'danger')
    
    return render_template("verify_reset_otp.html")

@app.route('/reset_password', methods=['GET', 'POST'])
def reset_password():
    # Check if the user has verified OTP
    if 'reset_email' not in session or 'reset_otp' not in session:
        flash("Unauthorized access. Please start the password reset process again.", 'danger')
        return redirect(url_for('forgot_password'))
    
    if request.method == 'POST':
        new_password = request.form.get('new_password')
        confirm_password = request.form.get('confirm_password')

        if not new_password or not confirm_password:
            flash("Please fill in all fields.", 'danger')
            return redirect(url_for('reset_password'))

        if new_password != confirm_password:
            flash("Passwords do not match.", 'danger')
            return redirect(url_for('reset_password'))
        
        if len(new_password) < 6:
            flash("Password must be at least 6 characters long.", 'danger')
            return redirect(url_for('reset_password'))

        hashed_pw = generate_password_hash(new_password)
        email = session.get('reset_email')
        
        conn = db_connection()
        cursor = conn.cursor()
        try:
            cursor.execute("UPDATE register SET password_hash = %s WHERE email = %s", (hashed_pw, email))
            conn.commit()

            # Clear session values
            session.pop('reset_email', None)
            session.pop('reset_otp', None)
            session.pop('reset_otp_expiry', None)

            flash("Password reset successful. You can now login with your new password.", 'success')
            return redirect(url_for('login'))
        except Exception as e:
            conn.rollback()
            flash('Error resetting password. Please try again.', 'danger')
            app.logger.error(f"Error in reset password: {str(e)}")
        finally:
            conn.close()

    return render_template('reset_password.html')

@app.route('/resend_otp')
def resend_otp():
    if 'reset_email' not in session:
        flash("Session expired. Please start the password reset process again.", 'danger')
        return redirect(url_for('forgot_password'))
    
    email = session['reset_email']
    otp = generate_otp()
    success, error = send_otp_email(email, otp)
    
    if success:
        session['reset_otp'] = otp
        session['reset_otp_expiry'] = (datetime.now() + timedelta(minutes=5)).timestamp()
        flash('New OTP has been sent to your email.', 'success')
    else:
        flash(f"Error sending OTP: {error}", 'danger')
    
    return redirect(url_for('verify_reset_otp'))

#######################
# Authentication Routes
#######################

@app.route('/', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        email = request.form.get('email')
        password = request.form.get('password')

        if not email or not password:
            flash('Please fill in all fields', 'danger')
            return redirect(url_for('login'))

        conn = db_connection()
        cursor = conn.cursor()
        try:
            cursor.execute("SELECT * FROM register WHERE email=%s", (email,))
            user = cursor.fetchone()
            
            if user and check_password_hash(user['password_hash'], password):
                # Check if user is active
                if user['status'] != 'active':
                    flash('Your account is disabled. Please contact administrator.', 'danger')
                    return redirect(url_for('login'))
                
                session.clear()
                session['user_id'] = user['id']
                session['role'] = user['role']
                session['name'] = user['name']
                session.permanent = True
                
                flash('Login successful!', 'success')

                # Redirect based on role
                redirect_routes = {
                    'super_admin': 'super_admin_dashboard',
                    'admin': 'admin_dashboard',
                    'architect': 'architect_dashboard',
                    'site_engineer': 'site_engineer_dashboard',
                    'accountant': 'accountant_dashboard',
                    'project_manager': 'project_manager_dashboard'
                }
                return redirect(url_for(redirect_routes.get(user['role'], 'login')))
            else:
                flash('Invalid email or password.', 'danger')
        except Exception as e:
            flash('Database error occurred.', 'danger')
            app.logger.error(f"Database error in login: {str(e)}")
        finally:
            conn.close()

    return render_template('login.html')

@app.route('/super_admin/register', methods=['GET', 'POST'])
def register_super_admin():
    conn = db_connection()
    cursor = conn.cursor()

    try:
        # Check if a super admin already exists
        cursor.execute("SELECT COUNT(*) AS count FROM register WHERE role = 'super_admin'")
        result = cursor.fetchone()
        if result and result['count'] > 0:
            flash('Super admin already exists. Please login instead.', 'warning')
            return redirect(url_for('login'))

        if request.method == 'POST':
            name = request.form.get('name')
            email = request.form.get('email')
            contact_no = request.form.get('contact_no')
            password = request.form.get('password')

            if not all([name, email, contact_no, password]):
                flash('Please fill in all fields', 'danger')
                return render_template('register_super_admin.html')

            # Check if email already exists
            cursor.execute("SELECT * FROM register WHERE email = %s", (email,))
            if cursor.fetchone():
                flash('Email already exists. Please use a different email.', 'warning')
                return render_template('register_super_admin.html')

            # Hash the password before saving
            hashed_password = generate_password_hash(password)

            # Insert the new super admin into the database
            cursor.execute("""
                INSERT INTO register (name, email, password_hash, role, contact_no, status,org_id)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
            """, (name, email, hashed_password, 'super_admin', contact_no, 'active',0))
            conn.commit()
            
            # Get the ID of the newly inserted user
            new_user_id = cursor.lastrowid
            
            # Clear any existing session and set new session
            session.clear()
            session['user_id'] = new_user_id
            session['role'] = 'super_admin'
            session['name'] = name
            
            # Force session to be saved
            session.permanent = True
            
            flash("Super Admin registered and logged in successfully!", "success")
            return redirect(url_for('super_admin_dashboard'))
            
    except Exception as e:
        conn.rollback()
        flash(f'Error occurred during registration: {str(e)}', 'danger')
        app.logger.error(f"Error in super admin registration: {str(e)}")
        return render_template('register_super_admin.html')
    finally:
        conn.close()

    return render_template('register_super_admin.html')

@app.route('/logout')
def logout():
    session.clear()
    flash('Logged out successfully.', 'info')
    return redirect(url_for('login'))

#######################
# Super Admin Routes
#######################

@app.route('/super_admin/dashboard')
@role_required('super_admin')
def super_admin_dashboard():
    role_filter = request.args.get('role')
    
    try:
        conn = db_connection()
        cursor = conn.cursor()

        # Get current logged-in user ID from session
        current_user_id = session.get('user_id')

        # Filter users by role
        if role_filter:
            cursor.execute("SELECT * FROM register WHERE role = %s ORDER BY id DESC", (role_filter,))
        else:
            cursor.execute("SELECT * FROM register ORDER BY id DESC")
        users = cursor.fetchall()

        # Get counts for dashboard
        cursor.execute("SELECT role, COUNT(*) as count FROM register GROUP BY role")
        role_counts = {row['role']: row['count'] for row in cursor.fetchall()}

        # Architects with assigned projects/sites
        cursor.execute("""
            SELECT 
                r.id AS architect_id,
                r.name AS architect_name,
                r.email,
                r.contact_no,
                r.status,
                p.project_name,
                s.site_name,
                s.location
            FROM register r
            LEFT JOIN projects p ON r.id = p.architect_id
            LEFT JOIN sites s ON p.site_id = s.site_id
            WHERE r.role = 'architect'
            ORDER BY r.id DESC
        """)
        architects = cursor.fetchall()

        # All Sites with Site Engineers
        cursor.execute("""
            SELECT s.*, r.name AS site_engineer_name
            FROM sites s
            LEFT JOIN register r ON s.site_engineer_id = r.id
        """)
        sites = cursor.fetchall()

        return render_template('super_admin_dashboard.html',
                            users=users,
                            current_user_id=current_user_id,  # Add this line
                            admin_count=role_counts.get('admin', 0),
                            architect_count=role_counts.get('architect', 0),
                            engineer_count=role_counts.get('site_engineer', 0),
                            accountant_count=role_counts.get('accountant', 0),
                            project_manager_count=role_counts.get('project_manager', 0),
                            architects=architects,
                            sites=sites,
                            role_filter=role_filter)
    except Exception as e:
        flash('Error fetching dashboard data.', 'danger')
        app.logger.error(f"Error in super admin dashboard: {str(e)}")
        return redirect(url_for('super_admin_dashboard'))
    finally:
        conn.close()

@app.route('/super_admin/create_user', methods=['GET', 'POST'])
@role_required('super_admin')
def create_user():
    if request.method == 'POST':
        name = request.form.get('name')
        email = request.form.get('email')
        contact_no = request.form.get('contact_no')
        password = request.form.get('password')
        role = request.form.get('role')
        company_name = request.form.get('company_name')
        company_address = request.form.get('company_address')
        company_phone = request.form.get('company_phone')
        company_email = request.form.get('company_email')
        gst_number = request.form.get('gst_number')
        bank_name = request.form.get('bank_name')
        bank_account = request.form.get('bank_account')
        ifsc_code = request.form.get('ifsc_code')
        terms_conditions = request.form.get('terms_conditions')

        # Validate required fields
        if not all([name, email, contact_no, password, role, company_name, company_address, company_phone, company_email]):
            flash('Please fill in all fields', 'danger')
            return redirect(url_for('create_user'))

        conn = db_connection()
        cursor = conn.cursor()
        try:
            # Step 1: Check if user already exists
            cursor.execute("SELECT 1 FROM register WHERE email = %s", (email,))
            if cursor.fetchone():
                flash('User already exists with this email.', 'warning')
                return redirect(url_for('create_user'))

            # Step 2: Hash password
            hashed_password = generate_password_hash(password)

            # Step 3: Insert into register without org_id
            cursor.execute("""
                INSERT INTO register (name, email, contact_no, password_hash, role, status,org_id)
                VALUES (%s, %s, %s, %s, %s, 'active', 0)
            """, (name, email, contact_no, hashed_password, role))
            conn.commit()
            user_id = cursor.lastrowid

            print(f"New user created with ID: {user_id}")
            
            org_id = None
            # Step 4: Insert into organization_master (org_id is auto-incremented)
            cursor.execute("""
                INSERT INTO organization_master 
                (admin_id, role, company_name, company_address, company_phone, company_email, gst_number, bank_name, bank_account, ifsc_code, terms_conditions)
                VALUES (%s, %s, %s, %s, %s, %s,%s, %s, %s, %s, %s)
            """, (user_id, role, company_name, company_address, company_phone, company_email, gst_number, bank_name, bank_account, ifsc_code, terms_conditions))
            conn.commit()
            org_id = cursor.lastrowid  # Get the auto-incremented org_id
            print(f"New organization created with ID: {org_id}")


            print(f"New user created with ID: {user_id} and org_id: {org_id}")
            # Step 5: Update user's org_id
            cursor.execute("""
                UPDATE register SET org_id = %s WHERE id = %s
            """, (org_id, user_id))
            conn.commit()

            print(f"User {user_id} updated with org_id: {org_id}")

            flash(f'{role.capitalize()} account created successfully.', 'success')
            return redirect(url_for('super_admin_dashboard'))

        except Exception as e:
            conn.rollback()
            flash('Error creating user.', 'danger')
            app.logger.error(f"Error creating user: {str(e)}")

        finally:
            conn.close()

    return render_template('create_user.html')


@app.route('/super_admin/edit_user/<int:user_id>', methods=['GET', 'POST'])
@role_required('super_admin')
def edit_user(user_id):
    conn = db_connection()
    cursor = conn.cursor()
    
    try:
        if request.method == 'POST':
            name = request.form.get('name')
            email = request.form.get('email')
            contact_no = request.form.get('contact_no')
            role = request.form.get('role')

            cursor.execute("""
                UPDATE register 
                SET name=%s, email=%s, contact_no=%s, role=%s
                WHERE id=%s
            """, (name, email, contact_no, role, user_id))
            conn.commit()
            flash("User updated successfully.", "success")
            return redirect(url_for('super_admin_dashboard'))

        cursor.execute("SELECT * FROM register WHERE id = %s", (user_id,))
        user = cursor.fetchone()
        if not user:
            flash('User not found.', 'danger')
            return redirect(url_for('super_admin_dashboard'))
            
        return render_template('edit_user.html', user=user)
    except Exception as e:
        conn.rollback()
        flash('Error updating user.', 'danger')
        app.logger.error(f"Error editing user: {str(e)}")
        return redirect(url_for('super_admin_dashboard'))
    finally:
        conn.close()

@app.route('/super_admin/delete_user/<int:user_id>')
@role_required('super_admin')
def delete_user(user_id):
    # Get current logged-in user ID
    current_user_id = session.get('user_id')
    
    # Prevent self-deletion
    if user_id == current_user_id:
        flash('You cannot delete your own account!', 'danger')
        return redirect(url_for('super_admin_dashboard'))
    
    try:
        conn = db_connection()
        cursor = conn.cursor()
        
        # Your existing delete logic here
        cursor.execute("DELETE FROM register WHERE id = %s", (user_id,))
        conn.commit()
        
        flash('User deleted successfully!', 'success')
    except Exception as e:
        flash('Error deleting user.', 'danger')
        app.logger.error(f"Error deleting user: {str(e)}")
    finally:
        conn.close()
    
    return redirect(url_for('super_admin_dashboard'))


@app.route('/super_admin/toggle_user_status/<int:user_id>/<status>')
@role_required('super_admin')
def toggle_user_status(user_id, status):
    # Get current logged-in user ID
    current_user_id = session.get('user_id')
    
    # Prevent self-disabling
    if user_id == current_user_id and status == 'disabled':
        flash('You cannot disable your own account!', 'danger')
        return redirect(url_for('super_admin_dashboard'))
    
    try:
        conn = db_connection()
        cursor = conn.cursor()
        
        # Your existing status toggle logic here
        cursor.execute("UPDATE register SET status = %s WHERE id = %s", (status, user_id))
        conn.commit()
        
        flash(f'User status updated to {status} successfully!', 'success')
    except Exception as e:
        flash('Error updating user status.', 'danger')
        app.logger.error(f"Error toggling user status: {str(e)}")
    finally:
        conn.close()
    
    return redirect(url_for('super_admin_dashboard'))
@app.route('/api/user_stats')
@role_required('super_admin')
def user_stats():
    conn = db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute("SELECT role, COUNT(*) as count FROM register GROUP BY role")
        role_counts = {row['role']: row['count'] for row in cursor.fetchall()}
        return jsonify({
            'admin_count': role_counts.get('admin', 0),
            'architect_count': role_counts.get('architect', 0),
            'engineer_count': role_counts.get('site_engineer', 0),
            'accountant_count': role_counts.get('accountant', 0),
            'project_manager_count': role_counts.get('project_manager', 0)
        })
    except Exception as e:
        app.logger.error(f"Error fetching user stats: {str(e)}")
        return jsonify({'error': 'Failed to fetch user stats'}), 500
    finally:
        conn.close()

#######################
# Dashboard Routes (Placeholder)
#######################

@app.route('/admin/dashboard')
@role_required('admin')
def admin_dashboard():
    return render_template('admin_dashboard.html')

@app.route('/architect/dashboard')
@role_required('architect')
def architect_dashboard():
    return render_template('architect_dashboard.html')

@app.route('/site_engineer/dashboard')
@role_required('site_engineer')
def site_engineer_dashboard():
    return render_template('site_engineer_dashboard.html')

@app.route('/accountant/dashboard')
@role_required('accountant')
def accountant_dashboard():
    return render_template('accountant_dashboard.html')

@app.route('/project_manager/dashboard')
@role_required('project_manager')
def project_manager_dashboard():
    return render_template('project_manager_dashboard.html')

#######################
# Test Routes (Remove in production)
#######################

@app.route('/test_session')
def test_session():
    return f"""
    <h2>Session Test</h2>
    <p><strong>Session contents:</strong> {dict(session)}</p>
    <p><strong>User ID:</strong> {session.get('user_id', 'Not set')}</p>
    <p><strong>Role:</strong> {session.get('role', 'Not set')}</p>
    <p><strong>Name:</strong> {session.get('name', 'Not set')}</p>
    <p><strong>Session ID:</strong> {session.sid if hasattr(session, 'sid') else 'Not available'}</p>
    """

@app.route('/test_db')
def test_db():
    try:
        conn = db_connection()
        cursor = conn.cursor()
        
        # Test basic connection
        cursor.execute("SELECT 1")
        result = cursor.fetchone()
        
        # Check if register table exists
        cursor.execute("SHOW TABLES LIKE 'register'")
        table_exists = cursor.fetchone()
        
        # Check register table structure
        cursor.execute("DESCRIBE register")
        table_structure = cursor.fetchall()
        
        # Check existing super_admin records
        cursor.execute("SELECT * FROM register WHERE role = 'super_admin'")
        super_admins = cursor.fetchall()
        
        conn.close()
        
        return f"""
        <h2>Database Test Results</h2>
        <p><strong>Connection:</strong> {'✓ Working' if result else '✗ Failed'}</p>
        <p><strong>Register Table:</strong> {'✓ Exists' if table_exists else '✗ Missing'}</p>
        <p><strong>Table Structure:</strong> {table_structure}</p>
        <p><strong>Super Admins:</strong> {super_admins}</p>
        """
    except Exception as e:
        return f"<h2>Database Error:</h2><p>{str(e)}</p>"

if __name__ == "__main__":
    app.run(debug=False, host='0.0.0.0', port=5000)
