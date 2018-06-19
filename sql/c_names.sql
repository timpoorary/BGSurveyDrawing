use l360;
CREATE TABLE reviews (
organization_reference varchar(128),
customer_reference varchar(128),
organization_id int,
public_reviewer_name varchar(128),
invited_at datetime,
unique_id int,
job_reference int,
net_promoter_label varchar(128),
flagged_for_follow_up boolean,
has_notes boolean,
notes text,
comments text,
recommendation_likelihood int,
customer_work_email varchar(128),
organization_name varchar(128),
censored boolean,
customer_full_name varchar(128),
updated_at datetime,
completed_at datetime,
public_response text
);

