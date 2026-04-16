"""add password reset code table

Revision ID: 002
Revises: 001
Create Date: 2026-04-15
"""

from alembic import op
import sqlalchemy as sa

revision = "002"
down_revision = "001"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "password_reset_code",
        sa.Column("id", sa.String(36), nullable=False),
        sa.Column("email", sa.String(100), nullable=False),
        sa.Column("code_hash", sa.String(128), nullable=False),
        sa.Column("is_used", sa.Boolean(), nullable=True),
        sa.Column("expires_at", sa.DateTime(), nullable=False),
        sa.Column("used_at", sa.DateTime(), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=True),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_password_reset_code_email", "password_reset_code", ["email"], unique=False)
    op.create_index("ix_password_reset_code_expires_at", "password_reset_code", ["expires_at"], unique=False)
    op.create_index("ix_password_reset_code_created_at", "password_reset_code", ["created_at"], unique=False)


def downgrade() -> None:
    op.drop_index("ix_password_reset_code_created_at", table_name="password_reset_code")
    op.drop_index("ix_password_reset_code_expires_at", table_name="password_reset_code")
    op.drop_index("ix_password_reset_code_email", table_name="password_reset_code")
    op.drop_table("password_reset_code")
