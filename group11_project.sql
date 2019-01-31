/**********************************************************
* Group 11 - Mental Health Clinic Data System *
* *
* Implemented by: Andrew Berry, Dhruv Yadav, Josh Wilson *
**********************************************************/

/*****************************
* DROP IF EXISTS Statements *
*****************************/
DROP VIEW IF EXISTS StudentHealthPrescriptionListView;
DROP VIEW IF EXISTS PatientCounselorRelationshipView;
DROP VIEW IF EXISTS PatientHistoryFeedback;
DROP TRIGGER IF EXISTS NoPatientIDInCounselor;
DROP TRIGGER IF EXISTS NoCounselorIDInPatient;
DROP TRIGGER IF EXISTS NoMoreThan10MedicationsPerIllnessInstance;
DROP TABLE IF EXISTS Directs;
DROP TABLE IF EXISTS Medication;
DROP TABLE IF EXISTS IllnessInstance;
DROP TABLE IF EXISTS Expertise;
DROP TABLE IF EXISTS Illness;
DROP TABLE IF EXISTS RSVP;
DROP TABLE IF EXISTS MeetingReminder;
DROP TABLE IF EXISTS Meeting;
DROP TABLE IF EXISTS Feedback;
DROP TABLE IF EXISTS Patient;
DROP TABLE IF EXISTS Counselor;
DROP TABLE IF EXISTS User;
DROP TABLE IF EXISTS Clinic;
/***************************
* CREATE TABLE Statements *
***************************/
/*
Clinic
Primary Author: Andrew Berry
Reviewers: Josh Wilson
*/
CREATE TABLE Clinic(
ClinicID INTEGER,
Name TEXT,
Address TEXT,
PhoneNumber TEXT,
Email TEXT,
PRIMARY KEY(ClinicID)
);

/*
User
Primary Author: Andrew Berry
Reviewers: Josh Wilson, Dhruv Yadav
Updates and deletes cascade here, since we likely can remove a clinic from the
database if all users affiliated with that clinic no longer exist.
*/
CREATE TABLE User(
UserID INTEGER,
Name TEXT,
Age INTEGER,
Gender TEXT,
PhoneNumber TEXT,
Email TEXT,
AffiliatedClinic INTEGER,
PRIMARY KEY(UserID),
FOREIGN KEY(AffiliatedClinic) REFERENCES Clinic(ClinicID)
ON DELETE CASCADE
ON UPDATE CASCADE
);
/*
Counselor
Primary Author: Andrew Berry
Reviewers: Josh Wilson, Dhruv Yadav
If a record is deleted or updated in Counselor, those same deletes/updates
should apply to the User relation, so the foreign key constraint to User is
cascading. This is because the Counselor is a User and the User relation
should reflect any change in the Counselor relation.
*/
CREATE TABLE Counselor(
UserID INTEGER,
Bio TEXT,
Picture TEXT, -- Stores file path to picture (jpg/png/etc)
PRIMARY KEY(UserID),
FOREIGN KEY(UserID) REFERENCES User(UserID)
ON DELETE CASCADE
ON UPDATE CASCADE
);
/*
Patient
Primary Author: Andrew Berry
Reviewers: Josh Wilson, Dhruv Yadav
Foreign key constraint to User cascades for the same reason as noted in the
comments for Counselor above.
*/

CREATE TABLE Patient(
UserID INTEGER,
ReasonForInitialVisit TEXT,
MeetingPreference TEXT,
IsHighRisk BOOLEAN,
PRIMARY KEY(UserID),
FOREIGN KEY(UserID) REFERENCES User(UserID)
ON DELETE CASCADE
ON UPDATE CASCADE,
CHECK(MeetingPreference IN ('Group','Individual'))
);
/*
Feedback
Primary Author: Andrew Berry
Reviewers: Josh Wilson, Dhruv Yadav
*/
CREATE TABLE Feedback(
CounselorID INTEGER,
PatientID INTEGER,
FeedbackDateTime DATETIME,
Helpfulness INTEGER NOT NULL,
Content TEXT,
CHECK(Helpfulness BETWEEN 1 AND 5),
PRIMARY KEY(CounselorID, PatientID, FeedbackDateTime),
FOREIGN KEY(CounselorID) REFERENCES Counselor(UserID)
ON DELETE RESTRICT
ON UPDATE RESTRICT,
FOREIGN KEY(PatientID) REFERENCES Patient(UserID)
ON DELETE RESTRICT
ON UPDATE RESTRICT
);
/*
Meeting
Primary Author: Andrew Berry
Reviewers: Josh Wilson, Dhruv Yadav
Since SQLite doesn’t strictly enforce the distinction between BOOLEAN and
other numeric types such as INTEGER, an in-table CHECK has been put in place
to make sure we only get 1 (true) and 0 (false) as values for IsPrivate.
isPrivate is 1 iff the meeting is a one-on-one meeting with a counselor.
*/
CREATE TABLE Meeting(
MeetingID INTEGER,
MeetingDateTime DATETIME,
MeetingTitle TEXT,
Location TEXT,
IsPrivate BOOLEAN,

PRIMARY KEY(MeetingID),
CHECK(IsPrivate IN (0, 1))
);
/*
MeetingReminder
Primary Author: Andrew Berry
Reviewers: Josh Wilson
Foreign keys to Patient and Meeting are cascading. This is because a patient
should not receive a reminder for meetings if the meeting no longer exists, or
if the patient has been deleted from the system.
None of the fields in this relation are allowed to be null, because the
reminder must be:
1. For a Patient
2. For a Meeting
3. Set at some DateTime
4. Have some method by which to be delivered (Email, text, etc)
HasBeenSent and HasBeenAcknowledged should never be null since they are
semantically 0 if the reminder has not been sent/has not been acknowledged.
*/
CREATE TABLE MeetingReminder(
PatientID INTEGER NOT NULL,
MeetingID INTEGER NOT NULL,
ReminderDateTime DATETIME NOT NULL,
DeliveryMethod TEXT NOT NULL,
HasBeenSent BOOLEAN NOT NULL,
HasBeenAcknowledged BOOLEAN NOT NULL,
PRIMARY KEY(PatientID, MeetingID, ReminderDateTime),
FOREIGN KEY(PatientID) REFERENCES Patient(UserID)
ON DELETE CASCADE
ON UPDATE CASCADE,
FOREIGN KEY(MeetingID) REFERENCES Meeting(MeetingID)
ON DELETE CASCADE
ON UPDATE CASCADE,
CHECK(HasBeenSent IN (0, 1)),
CHECK(HasBeenAcknowledged IN (0, 1))
);
/*
RSVP
Primary Author: Andrew Berry
Reviewers: Josh Wilson
*/
CREATE TABLE RSVP(
MeetingID INTEGER,
PatientID INTEGER,
DidRSVP BOOLEAN NOT NULL,
RSVPResponse TEXT,

DidAttend BOOLEAN,
PRIMARY KEY(MeetingID, PatientID),
FOREIGN KEY(MeetingID) REFERENCES Meeting(MeetingID)
ON DELETE RESTRICT
ON UPDATE RESTRICT,
FOREIGN KEY(PatientID) REFERENCES Patient(UserID)
ON DELETE RESTRICT
ON UPDATE RESTRICT
);
/*
Illness
Primary Author: Andrew Berry
Reviewers: Josh Wilson
*/
CREATE TABLE Illness(
IllnessName TEXT,
Description TEXT,
Symptoms TEXT,
PRIMARY KEY(IllnessName)
);
/*
Expertise
Primary Author: Andrew Berry
Reviewers: Josh Wilson, Dhruv Yadav
Foreign Key to Counselor cascades, since we would probably allow counselors to
be deleted/updated in the system, and any reference to them in Expertise could
be deleted/updated accordingly without causing issues.
Foreign key to illness does not cascade, since we would silently be
removing/updating records of counselor expertise in an area, which could cause
problems.
*/
CREATE TABLE Expertise(
CounselorID INTEGER,
IllnessName TEXT,
Credentials TEXT,
PRIMARY KEY(CounselorID, IllnessName),
FOREIGN KEY(CounselorID) REFERENCES Counselor(UserID)
ON DELETE CASCADE
ON UPDATE CASCADE,
FOREIGN KEY(IllnessName) REFERENCES Illness(IllnessName)
ON DELETE RESTRICT
ON UPDATE RESTRICT
);
/*

Primary Author: Andrew Berry
Reviewers: Josh Wilson, Dhruv Yadav
*/
CREATE TABLE IllnessInstance(
PatientID INTEGER,
IllnessName TEXT,
DiagnosisDate DATE,
Details TEXT,
Severity TEXT,
PRIMARY KEY(PatientID, IllnessName)
FOREIGN KEY(PatientID) REFERENCES Patient(UserID)
ON DELETE CASCADE
ON UPDATE CASCADE,
FOREIGN KEY(IllnessName) REFERENCES Illness(IllnessName)
ON DELETE CASCADE
ON UPDATE CASCADE,
CHECK(Severity IN ('Trivial','Mild','Moderate','Severe','Critical'))
);
/*
Medication
Primary Author: Andrew Berry
Reviewers: Josh Wilson, Dhruv Yadav
*/
CREATE TABLE Medication(
PatientID INTEGER,
IllnessName TEXT,
Drug TEXT,
DosageQuantity INTEGER,
DosageUnit TEXT,
Prescriber INTEGER,
PRIMARY KEY(PatientID, IllnessName, Drug),
FOREIGN KEY(PatientID) REFERENCES Patient(UserID)
ON DELETE CASCADE
ON UPDATE CASCADE,
FOREIGN KEY(IllnessName) REFERENCES Illness(IllnessName)
ON DELETE CASCADE
ON UPDATE CASCADE,
FOREIGN KEY(Prescriber) REFERENCES Counselor(UserID)
ON DELETE RESTRICT
ON UPDATE RESTRICT,
CHECK(DosageUnit IN ('g','mg','mcg','ml'))
);
/*
Directs
Primary Author: Josh Wilson

Reviewers: Andrew Berry
*/
CREATE TABLE Directs(
CounselorID INTEGER,
MeetingID INTEGER,
PRIMARY KEY(CounselorID, MeetingID),
FOREIGN KEY(CounselorID) REFERENCES Counselor(UserID)
ON DELETE RESTRICT
ON UPDATE RESTRICT,
FOREIGN KEY(MeetingID) REFERENCES Meeting(MeetingID)
);
/**************************
* CREATE VIEW Statements *
**************************/
/*
Primary Author: Dhruv Yadav
Reviewed By: Josh Wilson, Andrew Berry
This view allows counselors affiliated with Vanderbilt Student Health
to see feedback from each meeting and see how the progression goes.
*/
CREATE VIEW PatientHistoryFeedback AS
SELECT DISTINCT
UP.Name AS PatientName,
F.FeedbackDateTime,
F.Helpfulness,
F.Content,
UC.Name AS CounselorName
FROM
Patient P,
User UP,
Feedback F,
Counselor C,
User UC
WHERE
P.UserID = UP.UserID
AND UP.UserID = F.PatientID
AND F.CounselorID = C.UserID
AND C.UserID = UC.UserID
;
/*
Primary Author: Josh Wilson

Reviewed By: Andrew Berry
*/
CREATE VIEW PatientCounselorRelationshipView AS
SELECT DISTINCT
UP.Name as PatientName,
P.UserID as PatientID,
UC.Name as CounselorName,
C.UserID as CounselorID
FROM
Patient P,
User UP,
Counselor C,
User UC,
RSVP,
Directs
WHERE
C.UserID = Directs.CounselorID
AND C.UserID = UC.UserID
AND Directs.MeetingID = RSVP.MeetingID
AND RSVP.PatientID = P.UserID
AND P.UserID = UP.UserID
AND RSVP.DidAttend = 1
;
/*
Primary Author: Andrew Berry
Reviewed By: Josh Wilson, Dhruv Yadav
This view allows counselors affiliated with Vanderbilt Student Health
to see all prescriptions their patients are taking for their conditions.
*/
CREATE VIEW StudentHealthPrescriptionListView AS
SELECT
pu.Name AS PatientName,
m.IllnessName,
ii.Severity,
m.Drug,
m.DosageQuantity,
m.DosageUnit,
cu.Name AS PrescriberName
FROM
Patient p,
User pu,
IllnessInstance ii,
Medication m,
Counselor c,
User cu,

Clinic cl
WHERE
p.UserID = pu.UserID
AND p.UserID = ii.PatientID
AND ii.IllnessName = m.IllnessName
AND m.Prescriber = c.UserID
AND c.UserID = cu.UserID
AND cu.AffiliatedClinic = cl.ClinicID
AND cl.Name = 'Vanderbilt Student Health'
;
/*****************************
* CREATE TRIGGER Statements *
*****************************/
/*
Because inserting a member of a subclass is not an atomic operation but rather
two individual insertions, a trigger was not suitable for implementing the
Complete constraint specified in the UML diagram; we could only implement a
one-way foreign key and triggers to implement the Disjoint constraint.
*/
/*
NoMoreThan10MedicationsPerIllnessInstance
Primary Author: Andrew Berry
Reviewers: Josh Wilson, Dhruv Yadav
Matches the NoMoreThan10MedicationsPerIllnessInstance assertion. Patient can
have at most 10 medications prescribed per illness, so we check (before
insertion into Medication) that the count of medication records for the
Patient/Illness combination is < 10.
See RAISE(IGNORE) in https://www.sqlite.org/lang_createtrigger.html
*/
CREATE TRIGGER NoMoreThan10MedicationsPerIllnessInstance
BEFORE INSERT ON Medication
FOR EACH ROW
WHEN EXISTS (
SELECT m.PatientID, m.IllnessName, COUNT(*)
FROM Medication m
WHERE m.PatientID = NEW.PatientID
AND m.IllnessName = NEW.IllnessName
GROUP BY m.PatientID, m.IllnessName
HAVING COUNT(*) >= 10
)
BEGIN
SELECT RAISE(IGNORE);
END;

/*
NoCounselorIDInPatient
Primary Author: Josh Wilson
Reviewers: Andrew Berry, Dhruv Yadav
This is the first of two triggers that implements the
CounselorPatientDisjoint assertion; it cancels any insertion that would
create a Counselor with the same UserID as a Patient.
See RAISE(IGNORE) in https://www.sqlite.org/lang_createtrigger.html
*/
CREATE TRIGGER NoCounselorIDInPatient
BEFORE INSERT ON Counselor
FOR EACH ROW
WHEN NEW.UserID IN (SELECT UserID FROM Patient)
BEGIN
SELECT RAISE(IGNORE);
END;
/*
Primary Author: Dhruv Yadav
Reviewers: Andrew Berry, Josh Wilson
This is the second of two triggers that implements the
CounselorPatientDisjoint assertion; it cancels any insertion that would
create a Patient with the same UserID as a Counselor.
See RAISE(IGNORE) in https://www.sqlite.org/lang_createtrigger.html
*/
CREATE TRIGGER NoPatientIDInCounselor
BEFORE INSERT ON Patient
FOR EACH ROW
WHEN NEW.UserID IN (SELECT UserID FROM Counselor)
BEGIN
SELECT RAISE(IGNORE);
END;
/*********************
* INSERT Statements *
*********************/
--Clinic (Vanderbilt Student Health)
INSERT INTO Clinic(ClinicID, Name, Address, PhoneNumber, Email)
VALUES (1, 'Vanderbilt Student Health', '1210 Stevenson Ctr Ln,
Nashville, TN 37232', '(615) 322-2427', 'studenthealth@vanderbilt.edu');

--User (Chaz M., Gregory House, Jane B., John C., Barbara Smith)
INSERT INTO User(UserID, Name, Age, Gender, PhoneNumber, Email,
AffiliatedClinic)
VALUES (1, 'Chaz M.', 21, 'M', '(615) 555-0300', 'chaz@vanderbilt.edu',
1);
INSERT INTO User(UserID, Name, Age, Gender, PhoneNumber, Email,
AffiliatedClinic)
VALUES (2, 'Dr. Gregory House', 42, 'M', '(615) 322-0000',
'gregory.house@vanderbilt.edu', 1);
INSERT INTO User(UserID, Name, Age, Gender, PhoneNumber, Email,
AffiliatedClinic)
VALUES (3,'Jane B.',20,'F','(615) 555-0100', 'jane.b@vanderbilt.edu',1);
INSERT INTO User(UserID, Name, Age, Gender, PhoneNumber, Email,
AffiliatedClinic)
VALUES (4,'John C.',19,'M','(615) 555-0202', 'john.m.c@vanderbilt.edu',
1);
INSERT INTO User(UserID, Name, Age, Gender, PhoneNumber, Email,
AffiliatedClinic)
VALUES (5, 'Dr. Barbara Smith', 36, 'F', '(615) 789-0123',
'barb.smith@vanderbilt.edu',1);

--Counselor (Dr. House, Dr. Smith)
INSERT INTO Counselor(UserID, Bio, Picture)
VALUES (2, 'Dr. House has worked in all areas of psychological disorder,
but specializes in the treatment of addiction.',
'/img/hugh_laurie_portrait.jpg');
INSERT INTO Counselor(UserID, Bio, Picture)
VALUES (5, 'Dr. Smith has worked with Vanderbilt Student Health for the
last 6 years. She specializes in treating anxiety and depression.',
'/img/barb_smith.png');

--Patient (Chaz M., Jane B, John C)
INSERT INTO Patient(UserID, ReasonForInitialVisit, MeetingPreference,
IsHighRisk)
VALUES (1, 'Addiction to Mountain Dew', 'Group', 0);
INSERT INTO Patient(UserID, ReasonForInitialVisit, MeetingPreference,
IsHighRisk)
VALUES (3, 'Anxiety', 'Individual', 0);
INSERT INTO Patient(UserID, ReasonForInitialVisit, MeetingPreference,
IsHighRisk)
VALUES (4, 'Depression', 'Group', 1);

--Feedback
INSERT INTO Feedback(CounselorID, PatientID, FeedbackDateTime, Helpfulness,
Content)
VALUES (2, 1, '2018-01-13', 4, 'Dr. House can be a bit blunt and
boorish at times, but all in all his suggestions have worked well for me.');
INSERT INTO Feedback(CounselorID, PatientID, FeedbackDateTime, Helpfulness,
Content)
VALUES(2, 3, '2018-02-14',2,null);
INSERT INTO Feedback(CounselorID, PatientID, FeedbackDateTime, Helpfulness,
Content)
VALUES(2, 3, '2018-02-15',1,null);
INSERT INTO Feedback(CounselorID, PatientID, FeedbackDateTime, Helpfulness,
Content)
VALUES(2, 3, '2018-02-16',1,null);
INSERT INTO Feedback(CounselorID, PatientID, FeedbackDateTime, Helpfulness,
Content)
VALUES(2, 3, '2018-02-17',3,null);
INSERT INTO Feedback(CounselorID, PatientID, FeedbackDateTime, Helpfulness,
Content)
VALUES(2, 3, '2018-02-18',2,null);
--Meeting
INSERT INTO Meeting(MeetingID, MeetingDateTime, MeetingTitle, Location,
IsPrivate)
VALUES (1, '2018-01-10 10:30:00 a.m.', 'Coping with Substance Abuse
Issues', 'Starbucks', 0);
INSERT INTO Meeting(MeetingID, MeetingDateTime, MeetingTitle, Location,
IsPrivate)
VALUES (2, '2018-01-28 12:00:00 p.m.', 'Calming Anxiety', 'Student
Health Room 202', 1);

--MeetingReminder
INSERT INTO MeetingReminder(PatientID, MeetingID, ReminderDateTime,
DeliveryMethod, HasBeenSent, HasBeenAcknowledged)
VALUES (1, 1, '2018-01-09 8:00:00 p.m.', 'Email', 1, 1);
INSERT INTO MeetingReminder(PatientID, MeetingID, ReminderDateTime,
DeliveryMethod, HasBeenSent, HasBeenAcknowledged)
VALUES (1, 1, '2018-01-10 8:45:00 a.m.', 'Text', 1, 1);
--RSVP
INSERT INTO RSVP(MeetingID, PatientID, DidRSVP, RSVPResponse, DidAttend)
VALUES (1, 1, 1, 'Going', 1);
INSERT INTO RSVP(MeetingID, PatientID, DidRSVP, RSVPResponse, DidAttend)
VALUES (2, 3, 1, 'Ill be there!', 1);
INSERT INTO RSVP(MeetingID, PatientID, DidRSVP, RSVPResponse, DidAttend)
VALUES (2, 4, 1, 'I will try to make it!', 0);
--Illness
INSERT INTO Illness(IllnessName, Description, Symptoms)
VALUES ('Addiction','Compulsive substance abuse despite harmful
consequence','<symptoms>');
INSERT INTO Illness(IllnessName, Description, Symptoms)
VALUES ('Anxiety','<some text about it>','<symptoms>');
INSERT INTO Illness(IllnessName, Description, Symptoms)
VALUES ('Bipolar Disorder','<some text about it>','<symptoms>');
INSERT INTO Illness(IllnessName, Description, Symptoms)
VALUES ('Depression','<some text about it>','<symptoms>');
INSERT INTO Illness(IllnessName, Description, Symptoms)
VALUES ('Obsessive Compulsive Disorder','<some text about
it>','<symptoms>');
INSERT INTO Illness(IllnessName, Description, Symptoms)
VALUES ('Schizophrenia','<some text about it>','<symptoms>');
--Expertise
INSERT INTO Expertise(CounselorID, IllnessName, Credentials)
VALUES (2, 'Addiction', 'Certificate in Addiction Counseling; Past
personal experience');
INSERT INTO Expertise(CounselorID, IllnessName, Credentials)
VALUES (5, 'Depression', '2 years prior experience');
INSERT INTO Expertise(CounselorID, IllnessName, Credentials)
VALUES (5, 'Anxiety', 'Certificate of Preparation for Anxiety
Treatment');
--IllnessInstance
INSERT INTO IllnessInstance(PatientID, IllnessName, DiagnosisDate, Details,
Severity)
VALUES (1, 'Addiction', '2018-01-03', 'Requires large doses of Mountain
Dew daily to function', 'Mild');
INSERT INTO IllnessInstance(PatientID, IllnessName, DiagnosisDate, Details,
Severity)
VALUES (3, 'Depression', '2017-08-12', 'Struggling with loss of pet',
'Moderate');
INSERT INTO IllnessInstance(PatientID, IllnessName, DiagnosisDate, Details,
Severity)
VALUES (4, 'Anxiety', '2017-12-10', 'Unknown cause, difficult to open
up', 'Moderate');
--Medication
INSERT INTO Medication(PatientID, IllnessName, Drug, DosageQuantity,
DosageUnit, Prescriber)
VALUES (1, 'Addiction', 'Vitamin B', '200', 'mg',2);
--Directs
INSERT INTO Directs(CounselorID, MeetingID) VALUES (2, 1);
INSERT INTO Directs(CounselorID, MeetingID) VALUES (5, 2);
/*********************
* Queries *
*********************/
/*
Query 1

Primary Author: Andrew Berry
Reviewers: Josh Wilson, Dhruv Yadav
Find “consistently unsatisfied” patients: those who have left feedback many
times but with consistently low rating. Return their name and contact
information to reach out and see what we can be doing differently.
*/
SELECT
U.Name,
U.Email,
U.PhoneNumber
FROM
User U,
Patient P,
Feedback F
WHERE
U.UserID = P.UserID
AND P.UserID = F.PatientID
GROUP BY
F.PatientID
HAVING
COUNT(*) >= 5
AND AVG(F.Helpfulness) < 3
;
/*
Query 2
Primary Author: Josh Wilson
Reviewers: Andrew Berry
List all patients that have missed 1 or more meetings, so that they may have
reminders sent more often.
*/
SELECT DISTINCT
UP.UserID as PatientID,
UP.Name,
UP.PhoneNumber
FROM
User UP,
Patient P,
RSVP
WHERE
RSVP.PatientID = P.UserID
AND P.UserID = UP.UserID
AND RSVP.DidAttend = 0
GROUP BY
P.UserID
HAVING
COUNT(*) >= 1
;

/*
Query 3
Primary Author: Josh Wilson
Reviewers: Andrew Berry, Dhruv Yadav
List all meetings along with their associated counselors, in chronological
order.
*/
SELECT
MeetingTitle,
MeetingDateTime,
Name
FROM
User UC,
Counselor C,
Directs D,
Meeting M
WHERE
UC.UserID = C.UserID
AND C.UserID = D.CounselorID
AND D.MeetingID = M.MeetingID
ORDER BY
MeetingDateTime, Name
;
/*
Query 4
Primary Author: Josh Wilson
Reviewers: Andrew Berry
List the number of counselors who specialize in each illness in the table.
*/
SELECT
COUNT (*) AS NumExperts,
IllnessName
FROM
Counselor C,
Expertise E
WHERE
E.CounselorID = C.UserID
GROUP BY
IllnessName
;

/*
Query 5
Primary Author: Andrew Berry
Reviewers: Josh Wilson

List the contact information of patients who have never given an RSVP to a
meeting.
*/
SELECT
U.Name,
U.Email,
U.PhoneNumber
FROM
User U,
Patient P
WHERE
U.UserID = P.UserID
AND NOT EXISTS (
	SELECT *
	FROM RSVP R
	WHERE R.PatientID = p.UserID
	AND R.DidRSVP = 1
)
;
/*
Query 6
Primary Author: Dhruv Yadav
Reviewers: Josh Wilson, Andrew Berry
List the meeting name and time and the contact information of patients who did
RSVP for a particular meeting but did not attend that meeting, or vice versa.
*/
SELECT
U.Name,
U.Email,
U.PhoneNumber,
M.MeetingTitle,
M.MeetingDateTime
FROM
User U,
Patient P,
RSVP R,
Meeting M
WHERE
U.UserID = P.UserID
AND P.UserID = R.PatientID
AND R.MeetingID = M.MeetingID
AND R.DidRSVP <> R.DidAttend
GROUP BY
M.MeetingDateTime
;

/*
Query 7
Primary Author: Dhruv Yadav
Reviewers: Josh Wilson, Andrew Berry
List all patients who are currently at high risk so that a counselor can
monitor their progress.
*/
SELECT
U.Name,
U.Email,
U.PhoneNumber
FROM
User U,
Patient P
WHERE
U.UserID = P.UserID
AND P.IsHighRisk = 1
;
/*
Query 8
Primary Author: Josh Wilson
Reviewers: Andrew Berry, Dhruv Yadav
List all patients who prefer group meetings and do not suffer from addiction.
*/
SELECT
U.Name,
U.UserID,
U.Email
FROM
User U,
Patient P
WHERE
U.UserID = P.UserID
AND P.MeetingPreference = 'Group'
AND NOT EXISTS (
SELECT *
FROM IllnessInstance II
WHERE P.UserID = II.PatientID
AND IllnessName = 'Addiction'
)
;
/*
Query 9
Primary Author: Josh Wilson
Reviewers: Andrew Berry, Dhruv Yadav

Finds all counselors with expertise in multiple areas.
*/
SELECT
U.UserID, U.Name
FROM
User U,
Counselor C
WHERE U.UserID = C.UserID
AND (
	SELECT COUNT(*)
	FROM Expertise E
	WHERE E.CounselorID = C.UserID
) > 1
;

/*
Query 10
Primary Author: Josh Wilson
Reviewers: Andrew Berry, Dhruv Yadav
Shows all meeting reminders sent via text.
*/
SELECT
MR.ReminderDateTime,
U.Name,
U.UserID,
MR.MeetingID
FROM
MeetingReminder MR,
User U,
Patient P
WHERE
MR.PatientID = U.UserID
AND U.UserID = P.UserID
AND MR.DeliveryMethod = 'Text'
;

/*****************************
* DROP IF EXISTS Statements *
*****************************/
DROP VIEW IF EXISTS StudentHealthPrescriptionListView;
DROP VIEW IF EXISTS PatientCounselorRelationshipView;
DROP VIEW IF EXISTS PatientHistoryFeedback;
DROP TRIGGER IF EXISTS NoPatientIDInCounselor;
DROP TRIGGER IF EXISTS NoCounselorIDInPatient;
DROP TRIGGER IF EXISTS NoMoreThan10MedicationsPerIllnessInstance;
DROP TABLE IF EXISTS Directs;

DROP TABLE IF EXISTS Medication;
DROP TABLE IF EXISTS IllnessInstance;
DROP TABLE IF EXISTS Expertise;
DROP TABLE IF EXISTS Illness;
DROP TABLE IF EXISTS RSVP;
DROP TABLE IF EXISTS MeetingReminder;
DROP TABLE IF EXISTS Meeting;
DROP TABLE IF EXISTS Feedback;
DROP TABLE IF EXISTS Patient;
DROP TABLE IF EXISTS Counselor;
DROP TABLE IF EXISTS User;
DROP TABLE IF EXISTS Clinic;

/*****************
* QUERY RESULTS *
*****************/
/*
Query 1:
Jane B.|jane.b@vanderbilt.edu|(615) 555-0100
*/
/*
Query 2:
4|John C.|(615) 555-0202
*/
/*
Query 3:
Coping with Substance Abuse Issues|2018-01-10 10:30:00 a.m.|Dr. Gregory House
Calming Anxiety|2018-01-28 12:00:00 p.m.|Dr. Barbara Smith
*/
/*
Query 4:
1|Addiction
1|Anxiety
1|Depression
*/
/*
Query 5:

*/
/*
Query 6:
John C.|john.m.c@vanderbilt.edu|(615) 555-0202|Calming Anxiety|2018-01-28
12:00:00 p.m.
*/
/*
Query 7
John C.|john.m.c@vanderbilt.edu|(615) 555-0202
*/
/*
Query 8
John C.|4|john.m.c@vanderbilt.edu
*/
/*
Query 9
5|Dr. Barbara Smith
*/
/*
Query 10
2018-01-10 8:45:00 a.m.|Chaz M.|1|1
*/
