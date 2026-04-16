# Copyright 2026 Jiacheng Ni
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""initial schema

Revision ID: 001
Revises: 
Create Date: 2026-04-14

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = '001'
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    # user_account
    op.create_table('user_account',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('username', sa.String(50), nullable=False),
        sa.Column('phone', sa.String(20), nullable=False),
        sa.Column('email', sa.String(100), nullable=True),
        sa.Column('password_hash', sa.String(255), nullable=False),
        sa.Column('role', sa.Enum('RESIDENT', 'WORKER', 'STATION_MANAGER', 'DISPATCHER', 'OPERATOR', 'ADMIN', name='roleenum'), nullable=False),
        sa.Column('real_name', sa.String(50), nullable=True),
        sa.Column('avatar_url', sa.String(500), nullable=True),
        sa.Column('is_active', sa.Boolean(), nullable=True),
        sa.Column('is_verified', sa.Boolean(), nullable=True),
        sa.Column('station_id', postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=True),
        sa.Column('updated_at', sa.DateTime(), nullable=True),
        sa.Column('last_login_at', sa.DateTime(), nullable=True),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('username'),
        sa.UniqueConstraint('phone'),
    )
    op.create_index('ix_user_account_phone', 'user_account', ['phone'], unique=False)
    op.create_index('ix_user_account_username', 'user_account', ['username'], unique=False)
    op.create_index('ix_user_account_station_id', 'user_account', ['station_id'], unique=False)

    # service_station
    op.create_table('service_station',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('name', sa.String(100), nullable=False),
        sa.Column('code', sa.String(20), nullable=False),
        sa.Column('address', sa.String(255), nullable=False),
        sa.Column('contact_phone', sa.String(20), nullable=True),
        sa.Column('manager_id', postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column('longitude', sa.Integer(), nullable=True),
        sa.Column('latitude', sa.Integer(), nullable=True),
        sa.Column('service_radius', sa.Integer(), nullable=True),
        sa.Column('status', sa.String(20), nullable=True),
        sa.Column('description', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=True),
        sa.Column('updated_at', sa.DateTime(), nullable=True),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('code'),
    )
    op.create_index('ix_service_station_code', 'service_station', ['code'], unique=False)

    # worker_profile
    op.create_table('worker_profile',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('service_types', sa.String(500), nullable=True),
        sa.Column('rating', sa.Integer(), nullable=True),
        sa.Column('total_orders', sa.Integer(), nullable=True),
        sa.Column('completed_orders', sa.Integer(), nullable=True),
        sa.Column('current_load', sa.Integer(), nullable=True),
        sa.Column('max_load', sa.Integer(), nullable=True),
        sa.Column('status', sa.String(20), nullable=True),
        sa.Column('id_number', sa.String(30), nullable=True),
        sa.Column('certificate_url', sa.String(500), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=True),
        sa.Column('updated_at', sa.DateTime(), nullable=True),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('user_id'),
        sa.ForeignKeyConstraint(['user_id'], ['user_account.id'], ),
    )

    # service_order
    op.create_table('service_order',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('order_no', sa.String(30), nullable=False),
        sa.Column('station_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('creator_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('service_type', sa.String(50), nullable=False),
        sa.Column('title', sa.String(200), nullable=False),
        sa.Column('description', sa.Text(), nullable=True),
        sa.Column('voice_transcript', sa.Text(), nullable=True),
        sa.Column('contact_name', sa.String(50), nullable=True),
        sa.Column('contact_phone', sa.String(20), nullable=True),
        sa.Column('service_address', sa.String(255), nullable=True),
        sa.Column('longitude', sa.Integer(), nullable=True),
        sa.Column('latitude', sa.Integer(), nullable=True),
        sa.Column('appointment_time', sa.DateTime(), nullable=True),
        sa.Column('status', sa.Enum('CREATED', 'PENDING_DISPATCH', 'PENDING_ACCEPT', 'PENDING_ARRIVE', 'IN_SERVICE', 'PENDING_CONFIRM', 'COMPLETED', 'AFTER_SALE', 'CLOSED', name='orderstatusenum'), nullable=True),
        sa.Column('urgency_level', sa.String(20), nullable=True),
        sa.Column('ai_category', sa.String(50), nullable=True),
        sa.Column('ai_risk_tags', sa.String(500), nullable=True),
        sa.Column('ai_summary', sa.Text(), nullable=True),
        sa.Column('assigned_worker_id', postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column('check_in_time', sa.DateTime(), nullable=True),
        sa.Column('check_in_longitude', sa.Integer(), nullable=True),
        sa.Column('check_in_latitude', sa.Integer(), nullable=True),
        sa.Column('check_in_code', sa.String(20), nullable=True),
        sa.Column('service_result', sa.Text(), nullable=True),
        sa.Column('abnormal_flag', sa.Boolean(), nullable=True),
        sa.Column('abnormal_reason', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=True),
        sa.Column('updated_at', sa.DateTime(), nullable=True),
        sa.Column('completed_at', sa.DateTime(), nullable=True),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('order_no'),
        sa.ForeignKeyConstraint(['creator_id'], ['user_account.id'], ),
        sa.ForeignKeyConstraint(['station_id'], ['service_station.id'], ),
    )
    op.create_index('ix_service_order_order_no', 'service_order', ['order_no'], unique=False)
    op.create_index('ix_service_order_service_type', 'service_order', ['service_type'], unique=False)
    op.create_index('ix_service_order_station_id', 'service_order', ['station_id'], unique=False)

    # dispatch_task
    op.create_table('dispatch_task',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('order_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('station_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('candidate_worker_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('dispatcher_user_id', postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column('score', sa.Integer(), nullable=True),
        sa.Column('status', sa.Enum('PENDING', 'ASSIGNED', 'ACCEPTED', 'REJECTED', 'REASSIGNED', name='dispatchstatusenum'), nullable=True),
        sa.Column('dispatch_reason', sa.Text(), nullable=True),
        sa.Column('reject_reason', sa.Text(), nullable=True),
        sa.Column('distance_score', sa.Integer(), nullable=True),
        sa.Column('type_match_score', sa.Integer(), nullable=True),
        sa.Column('load_score', sa.Integer(), nullable=True),
        sa.Column('urgency_score', sa.Integer(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=True),
        sa.Column('updated_at', sa.DateTime(), nullable=True),
        sa.Column('responded_at', sa.DateTime(), nullable=True),
        sa.PrimaryKeyConstraint('id'),
        sa.ForeignKeyConstraint(['dispatcher_user_id'], ['user_account.id'], ),
        sa.ForeignKeyConstraint(['order_id'], ['service_order.id'], ),
        sa.ForeignKeyConstraint(['station_id'], ['service_station.id'], ),
    )
    op.create_index('ix_dispatch_task_order_id', 'dispatch_task', ['order_id'], unique=False)

    # order_attachment
    op.create_table('order_attachment',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('order_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('file_key', sa.String(255), nullable=False),
        sa.Column('file_path', sa.String(500), nullable=False),
        sa.Column('file_name', sa.String(255), nullable=False),
        sa.Column('mime_type', sa.String(100), nullable=True),
        sa.Column('file_size', sa.Integer(), nullable=True),
        sa.Column('attachment_type', sa.String(30), nullable=False),
        sa.Column('uploaded_by', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('description', sa.String(500), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=True),
        sa.PrimaryKeyConstraint('id'),
        sa.ForeignKeyConstraint(['order_id'], ['service_order.id'], ),
    )
    op.create_index('ix_order_attachment_order_id', 'order_attachment', ['order_id'], unique=False)

    # message
    op.create_table('message',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('message_type', sa.Enum('SYSTEM', 'BUSINESS', 'ALERT', name='messagetypeenum'), nullable=False),
        sa.Column('title', sa.String(200), nullable=False),
        sa.Column('content', sa.Text(), nullable=True),
        sa.Column('related_order_id', postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column('is_read', sa.Boolean(), nullable=True),
        sa.Column('priority', sa.String(20), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=True),
        sa.Column('read_at', sa.DateTime(), nullable=True),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index('ix_message_user_id', 'message', ['user_id'], unique=False)

    # ai_review_log
    op.create_table('ai_review_log',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('order_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('task_type', sa.Enum('REVIEW', 'SUMMARY', 'CLASSIFY', 'ANALYSIS', name='aitasktypeenum'), nullable=False),
        sa.Column('model_name', sa.String(50), nullable=True),
        sa.Column('request_prompt', sa.Text(), nullable=True),
        sa.Column('response_content', sa.Text(), nullable=True),
        sa.Column('status', sa.Enum('PENDING', 'PROCESSING', 'COMPLETED', 'FAILED', 'CANCELLED', name='aitaskstatusenum'), nullable=True),
        sa.Column('confidence', sa.Integer(), nullable=True),
        sa.Column('category_suggestion', sa.String(50), nullable=True),
        sa.Column('urgency_suggestion', sa.String(20), nullable=True),
        sa.Column('risk_tags', sa.String(500), nullable=True),
        sa.Column('summary', sa.Text(), nullable=True),
        sa.Column('error_message', sa.Text(), nullable=True),
        sa.Column('tokens_used', sa.Integer(), nullable=True),
        sa.Column('cost', sa.Integer(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=True),
        sa.Column('completed_at', sa.DateTime(), nullable=True),
        sa.PrimaryKeyConstraint('id'),
        sa.ForeignKeyConstraint(['order_id'], ['service_order.id'], ),
    )
    op.create_index('ix_ai_review_log_order_id', 'ai_review_log', ['order_id'], unique=False)

    # audit_log
    op.create_table('audit_log',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('operator_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('role', sa.String(30), nullable=True),
        sa.Column('action', sa.String(100), nullable=False),
        sa.Column('resource_type', sa.String(50), nullable=True),
        sa.Column('resource_id', sa.String(100), nullable=True),
        sa.Column('before_snapshot', sa.Text(), nullable=True),
        sa.Column('after_snapshot', sa.Text(), nullable=True),
        sa.Column('request_id', sa.String(50), nullable=True),
        sa.Column('client_ip', sa.String(50), nullable=True),
        sa.Column('client_type', sa.String(20), nullable=True),
        sa.Column('source', sa.String(50), nullable=True),
        sa.Column('error_code', sa.String(50), nullable=True),
        sa.Column('stack_digest', sa.String(100), nullable=True),
        sa.Column('retry_count', sa.Integer(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=True),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index('ix_audit_log_operator_id', 'audit_log', ['operator_id'], unique=False)


def downgrade() -> None:
    op.drop_table('audit_log')
    op.drop_table('ai_review_log')
    op.drop_table('message')
    op.drop_table('order_attachment')
    op.drop_table('dispatch_task')
    op.drop_table('service_order')
    op.drop_table('worker_profile')
    op.drop_table('service_station')
    op.drop_table('user_account')
