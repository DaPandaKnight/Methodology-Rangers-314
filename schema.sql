-- ============================================================
-- Intelligent Talent Matching Platform — Database Schema
-- CSIT314 Group Project
-- ============================================================

-- Users table (shared auth for both candidates and employers)
CREATE TABLE users (
    user_id       INTEGER PRIMARY KEY AUTOINCREMENT,
    email         TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    role          TEXT NOT NULL CHECK (role IN ('candidate', 'employer')),
    created_at    DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Candidate profiles
CREATE TABLE candidates (
    candidate_id  INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id       INTEGER NOT NULL UNIQUE,
    full_name     TEXT NOT NULL,
    phone         TEXT,
    location      TEXT,
    education     TEXT NOT NULL,   -- e.g. "Bachelor of Computer Science"
    major         TEXT NOT NULL,   -- e.g. "Software Engineering"
    years_exp     INTEGER NOT NULL DEFAULT 0,
    skills        TEXT,            -- comma-separated list e.g. "Python, React, SQL"
    resume_path   TEXT,            -- path to uploaded resume file
    bio           TEXT,
    created_at    DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at    DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- Employer / company profiles
CREATE TABLE employers (
    employer_id   INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id       INTEGER NOT NULL UNIQUE,
    company_name  TEXT NOT NULL,
    industry      TEXT,
    company_size  TEXT,            -- e.g. "1-10", "11-50", "51-200", "200+"
    website       TEXT,
    description   TEXT,
    created_at    DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- Job postings
CREATE TABLE jobs (
    job_id        INTEGER PRIMARY KEY AUTOINCREMENT,
    employer_id   INTEGER NOT NULL,
    title         TEXT NOT NULL,
    description   TEXT NOT NULL,
    required_education TEXT,       -- e.g. "Bachelor's Degree"
    required_skills    TEXT,       -- comma-separated e.g. "Python, SQL, Docker"
    years_exp_required INTEGER DEFAULT 0,
    work_mode     TEXT NOT NULL CHECK (work_mode IN ('Remote', 'On-site', 'Hybrid')),
    location      TEXT NOT NULL,
    status        TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'closed', 'draft')),
    created_at    DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at    DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (employer_id) REFERENCES employers(employer_id) ON DELETE CASCADE
);

-- Candidate-to-job recommendations (top 10 jobs per candidate)
CREATE TABLE candidate_recommendations (
    rec_id        INTEGER PRIMARY KEY AUTOINCREMENT,
    candidate_id  INTEGER NOT NULL,
    job_id        INTEGER NOT NULL,
    score         REAL NOT NULL,   -- matching score 0.0 – 1.0
    generated_at  DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (candidate_id) REFERENCES candidates(candidate_id) ON DELETE CASCADE,
    FOREIGN KEY (job_id) REFERENCES jobs(job_id) ON DELETE CASCADE,
    UNIQUE (candidate_id, job_id)
);

-- Employer-to-candidate recommendations (top 10 candidates per job)
CREATE TABLE employer_recommendations (
    rec_id        INTEGER PRIMARY KEY AUTOINCREMENT,
    job_id        INTEGER NOT NULL,
    candidate_id  INTEGER NOT NULL,
    score         REAL NOT NULL,   -- matching score 0.0 – 1.0
    generated_at  DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (job_id) REFERENCES jobs(job_id) ON DELETE CASCADE,
    FOREIGN KEY (candidate_id) REFERENCES candidates(candidate_id) ON DELETE CASCADE,
    UNIQUE (job_id, candidate_id)
);

-- ============================================================
-- Indexes for common query patterns
-- ============================================================

-- Searching jobs by keyword (on title + description)
CREATE INDEX idx_jobs_title       ON jobs(title);
CREATE INDEX idx_jobs_status      ON jobs(status);
CREATE INDEX idx_jobs_employer    ON jobs(employer_id);

-- Filtering candidates by skills/education/experience
CREATE INDEX idx_candidates_exp   ON candidates(years_exp);
CREATE INDEX idx_candidates_edu   ON candidates(education);

-- Fast recommendation lookups
CREATE INDEX idx_candrec_candidate ON candidate_recommendations(candidate_id);
CREATE INDEX idx_emprec_job        ON employer_recommendations(job_id);

-- ============================================================
-- Seed data — sample jobs and candidates for development
-- ============================================================

INSERT INTO users (email, password_hash, role) VALUES
    ('alice@example.com',   'hashed_pw_1', 'candidate'),
    ('bob@example.com',     'hashed_pw_2', 'candidate'),
    ('charlie@example.com', 'hashed_pw_3', 'candidate'),
    ('techcorp@example.com','hashed_pw_4', 'employer'),
    ('webco@example.com',   'hashed_pw_5', 'employer');

INSERT INTO candidates (user_id, full_name, phone, location, education, major, years_exp, skills, bio) VALUES
    (1, 'Alice Johnson', '0412345678', 'Sydney, NSW', 'Bachelor of Computer Science', 'Software Engineering', 2, 'Python, React, SQL, Git', 'Junior developer passionate about full-stack development.'),
    (2, 'Bob Smith',     '0423456789', 'Melbourne, VIC', 'Bachelor of Information Technology', 'Data Science', 4, 'Python, Machine Learning, Pandas, SQL', 'Data analyst with strong ML background.'),
    (3, 'Charlie Lee',   '0434567890', 'Brisbane, QLD', 'Master of Computer Science', 'Cybersecurity', 6, 'Java, Spring Boot, Docker, Kubernetes', 'Backend engineer specialising in secure systems.');

INSERT INTO employers (user_id, company_name, industry, company_size, website, description) VALUES
    (4, 'TechCorp Australia', 'Software', '51-200', 'https://techcorp.com.au', 'Building enterprise software solutions across APAC.'),
    (5, 'WebCo',             'Digital Agency', '11-50', 'https://webco.com.au', 'Full-service digital agency focused on web and mobile.');

INSERT INTO jobs (employer_id, title, description, required_education, required_skills, years_exp_required, work_mode, location, status) VALUES
    (1, 'Junior Frontend Developer',
     'We are looking for a motivated junior frontend developer to join our growing team. You will build responsive web interfaces using React and collaborate with backend engineers.',
     'Bachelor''s Degree', 'React, JavaScript, CSS, Git', 1, 'Hybrid', 'Sydney, NSW', 'open'),

    (1, 'Data Analyst',
     'Analyse large datasets to generate business insights. Work closely with product and engineering teams to drive data-informed decisions.',
     'Bachelor''s Degree', 'Python, SQL, Pandas, Tableau', 2, 'Remote', 'Sydney, NSW', 'open'),

    (1, 'Backend Engineer',
     'Design and maintain scalable backend services. Experience with microservices architecture and containerisation required.',
     'Bachelor''s Degree', 'Java, Spring Boot, Docker, PostgreSQL', 4, 'On-site', 'Melbourne, VIC', 'open'),

    (2, 'Full Stack Developer',
     'Own features end-to-end across our React frontend and Node.js backend. Join a fast-moving team building consumer-facing web products.',
     'Bachelor''s Degree', 'React, Node.js, SQL, REST APIs', 3, 'Hybrid', 'Brisbane, QLD', 'open'),

    (2, 'UI/UX Designer',
     'Create intuitive and beautiful user experiences. You will run user research, produce wireframes, and collaborate closely with developers.',
     'Bachelor''s Degree', 'Figma, User Research, Prototyping, CSS', 2, 'Remote', 'Remote', 'open');
