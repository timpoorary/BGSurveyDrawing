use l360;
CREATE TABLE drawing_reviews (
    censored varchar(10),
    comments text,
    completeDate datetime,
    followup varchar(10),
    hasNotes varchar(10),
    inviteDate datetime,
    netPromoterLabel varchar(128),
    ordId int,
    publicResponce varchar(10),
    recommendLikelihood int,
    updatedDate datetime,
    uniqueID int,
    jobRef int,
    orgRef varchar(128),
    orgName varchar(128),
    custRef varchar(128),
    custFullName varchar(128),
    custWorkEmail varchar(128),
    publicReviewerName varchar(128),
    notes text    
);
