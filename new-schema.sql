-- Drop tables if exists
DROP TABLE IF EXISTS registered_users CASCADE;

DROP TABLE IF EXISTS topics CASCADE;

DROP TABLE IF EXISTS posts CASCADE;

DROP TABLE IF EXISTS comments CASCADE;

DROP TABLE IF EXISTS votes CASCADE;

-- Registered Users table
CREATE TABLE registered_users (
    user_id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    CONSTRAINT username_length CHECK (Length(Trim(username)) > 0),
    last_login TIMESTAMP
);

-- Topics table
CREATE TABLE topics (
    topic_id SERIAL PRIMARY KEY,
    topic_name VARCHAR(30) UNIQUE NOT NULL,
    CONSTRAINT topic_name_length CHECK (Length(Trim(topic_name)) > 0),
    description VARCHAR(500),
    created_by_user_id INTEGER
);

-- Posts table
CREATE TABLE posts (
    post_id SERIAL PRIMARY KEY,
    title VARCHAR(100) NOT NULL,
    CONSTRAINT title_length CHECK (Length(Trim(title)) > 0),
    url TEXT,
    post_text TEXT,
    CONSTRAINT post_text_length CHECK (Length(Trim(post_text)) > 0),
    created_by_user_id INTEGER,
    topic_id INTEGER,
    CONSTRAINT fk_user FOREIGN KEY (created_by_user_id) REFERENCES registered_users (user_id) ON DELETE
    SET
        NULL,
        CONSTRAINT fk_topic FOREIGN KEY (topic_id) REFERENCES topics (topic_id) ON DELETE CASCADE,
        CONSTRAINT check_text_or_url_exists CHECK (
            (
                url IS NULL
                AND post_text IS NOT NULL
            )
            OR (
                url IS NOT NULL
                AND post_text IS NULL
            )
        ),
        post_timestamp TIMESTAMP
);

-- Comments table
CREATE TABLE comments (
    comment_id SERIAL PRIMARY KEY,
    comment_text TEXT NOT NULL,
    CONSTRAINT comment_length CHECK (Length(Trim(comment_text)) > 0),
    created_by_user_id INTEGER,
    topic_id INTEGER,
    post_id INTEGER,
    parent_comment_id INTEGER DEFAULT NULL,
    CONSTRAINT fk_user FOREIGN KEY (created_by_user_id) REFERENCES registered_users (user_id) ON DELETE
    SET
        NULL,
        CONSTRAINT fk_topic FOREIGN KEY (topic_id) REFERENCES topics (topic_id) ON DELETE CASCADE,
        CONSTRAINT fk_post FOREIGN KEY (post_id) REFERENCES posts (post_id) ON DELETE CASCADE,
        CONSTRAINT comment_thread FOREIGN KEY (parent_comment_id) REFERENCES comments (comment_id) ON DELETE CASCADE
);

-- Votes table
CREATE TABLE votes (
    vote_id SERIAL PRIMARY KEY,
    vote_value INTEGER NOT NULL,
    CONSTRAINT vote_value_check CHECK (
        vote_value = 1
        OR vote_value = -1
    ),
    voter_user_id INTEGER,
    post_id INTEGER,
    CONSTRAINT fk_user FOREIGN KEY (voter_user_id) REFERENCES registered_users (user_id) ON DELETE
    SET
        NULL,
        CONSTRAINT fk_post FOREIGN KEY (post_id) REFERENCES posts (post_id) ON DELETE CASCADE
);

-- List all users who haven’t logged in in the last year.
CREATE INDEX idx_users_by_last_login ON registered_users (last_login);

-- Find a user by their username.
CREATE INDEX idx_users_by_username ON registered_users (username);

-- List all users who haven’t created any post.
CREATE INDEX idx_users_with_posts ON posts (created_by_user_id);

-- List all topics that don’t have any posts.
CREATE INDEX idx_topics_with_posts ON posts (topic_id);

-- Find a topic by its name.
CREATE INDEX idx_topics_by_name ON topics (topic_name);

-- List the latest 20 posts for a given topic.
CREATE INDEX idx_posts_timestamp_by_topic ON posts (topic_id, post_timestamp DESC);

-- List the latest 20 posts made by a given user.
CREATE INDEX idx_posts_timestamp_by_user ON posts (created_by_user_id, post_timestamp DESC);

-- Find all posts that link to a specific URL, for moderation purposes.
CREATE INDEX idx_posts_by_url ON posts (url);

-- List all the top-level comments (those that don’t have a parent comment) for a given post.
CREATE INDEX idx_top_level_comments_by_post ON comments (post_id, parent_comment_id)
WHERE
    parent_comment_id IS NULL;

-- List all the direct children of a parent comment.
CREATE INDEX idx_direct_children_of_comment ON comments (parent_comment_id);

-- List the latest 20 comments made by a given user.
CREATE INDEX idx_latest_comments_by_user ON comments (created_by_user_id, comment_id DESC);

-- Compute the score of a post, defined as the difference between the number of upvotes and the number of downvotes.
CREATE INDEX idx_score_of_post ON votes (post_id, vote_value);