import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

from config import GMAIL_APP_PASSWORD, GMAIL_USER


def send_reset_email(to_email: str, code: str, user_name: str) -> None:
    """Send a password reset OTP to the user's email via Gmail SMTP."""
    msg = MIMEMultipart("alternative")
    msg["Subject"] = "Your Password Reset Code — Disaster Compensation App"
    msg["From"] = GMAIL_USER
    msg["To"] = to_email

    plain = (
        f"Hello {user_name},\n\n"
        f"Your password reset code is: {code}\n\n"
        f"This code expires in 15 minutes.\n"
        f"If you did not request this, ignore this email."
    )

    html = f"""
    <html>
      <body style="font-family: Arial, sans-serif; background: #f5f5f5; padding: 24px;">
        <div style="max-width: 480px; margin: auto; background: white;
                    border-radius: 12px; padding: 32px; box-shadow: 0 2px 8px rgba(0,0,0,0.08);">
          <h2 style="color: #1B5E20; margin-top: 0;">Password Reset Request</h2>
          <p style="color: #555;">Hello <strong>{user_name}</strong>,</p>
          <p style="color: #555;">Use the code below to reset your password.
             It expires in <strong>15 minutes</strong>.</p>
          <div style="text-align: center; margin: 28px 0;">
            <span style="font-size: 36px; font-weight: bold; letter-spacing: 8px;
                         color: #2E7D32; background: #E8F5E9; padding: 16px 28px;
                         border-radius: 10px;">{code}</span>
          </div>
          <p style="color: #888; font-size: 13px;">
            If you did not request a password reset, you can safely ignore this email.
          </p>
        </div>
      </body>
    </html>
    """

    msg.attach(MIMEText(plain, "plain"))
    msg.attach(MIMEText(html, "html"))

    with smtplib.SMTP_SSL("smtp.gmail.com", 465) as server:
        server.login(GMAIL_USER, GMAIL_APP_PASSWORD)
        server.sendmail(GMAIL_USER, to_email, msg.as_string())
