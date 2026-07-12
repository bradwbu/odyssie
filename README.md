# Odyssie

A fully-featured, real-time Twitter clone built with Elixir/Phoenix, replicating the exact feature set and UI paradigm of Twitter circa 2021 (pre-Elon Musk / pre-X rebranding).

## Tech Stack

- **Language/Framework:** Elixir 1.14+ with Phoenix Framework 1.7
- **Real-time:** Phoenix LiveView + PubSub
- **Database:** PostgreSQL via Ecto
- **Auth:** bcrypt password hashing, token-based sessions
- **Frontend:** Tailwind CSS, vanilla JS hooks
- **Architecture:** OTP supervision tree, GenServers for background work

## Features

### Posts & Threads
- 280-character limit with live character counter
- Automatic `#hashtag` and `@mention` parsing into clickable links
- Posts, Replies, Reposts, and Quote Posts
- Thread view with parent chain context and nested reply tree

### Social Graph & Profiles
- Asymmetric Follow/Unfollow system
- Public vs. Private account toggle
- Rich profiles with avatar, header image, bio, location, website, join date
- Profile tabs: Posts, Posts & Replies, Media, Likes
- Verified badge (blue checkmark)
- Denormalized follower/following/post counts for performance

### Real-Time Direct Messages
- 1-on-1 private messaging via PubSub
- DM Inbox sorted by most recent message
- Unread message badges
- Auto-scrolling conversation view
- Atomic mark-as-read

### Timelines & Notifications
- **Home Timeline:** Chronological feed from followed accounts with cursor-based pagination
- **New Posts Indicator:** "Show N new posts" pill at top of feed
- **Notifications:** All/Mentions tabs tracking likes, reposts, follows, mentions, replies
- Real-time notification delivery via PubSub

## Architecture

```
lib/
├── odyssie/
│   ├── accounts/          # Users, follows, tokens, presence
│   ├── feed/              # Posts, likes, reposts, timeline assembly
│   ├── chat/              # Messages, conversations, DM subscriptions
│   ├── notifications/     # Notification CRUD and real-time dispatch
│   └── timeline/          # PubSub topic helpers
├── odyssie_web/
│   ├── live/              # Phoenix LiveViews
│   │   ├── home_live/     # Home timeline feed
│   │   ├── profile_live/  # User profiles with tab switching
│   │   ├── chat_live/     # DM inbox and conversation view
│   │   ├── post_live/     # Post detail/thread and compose
│   │   ├── notification_live/  # Notifications feed
│   │   ├── search_live/   # Explore/search page
│   │   └── auth_live/     # Login and registration
│   ├── components/        # CoreComponents, Layouts
│   ├── controllers/       # Session API
│   └── plugs/             # Auth plugs
└── priv/repo/migrations/  # 8 database migrations
```

## Database Schema

| Table | Purpose |
|-------|---------|
| `users` | User accounts with profile fields, counters, verified/private flags |
| `posts` | Posts with type enum (post/reply/repost/quote), parent/source FKs |
| `follows` | Asymmetric follow graph with unique compound index |
| `likes` | User-post like relationships with unique constraint |
| `reposts` | User-post repost relationships with unique constraint |
| `messages` | Direct messages with sender/recipient and read_at timestamp |
| `notifications` | Notification events (like/repost/follow/mention/reply) |
| `tokens` | Session tokens with expiry |

## Real-Time PubSub Topics

| Topic | Purpose |
|-------|---------|
| `home_timeline:{user_id}` | New posts from followed users |
| `user:{user_id}/notifications` | Notification pushes |
| `dm:{user_a}:{user_b}` | Bidirectional DM channel |
| `user:{user_id}/dm_inbox` | Inbox update events |
| `timeline:{user_id}` | Profile timeline updates |

## Getting Started

### Prerequisites
- Elixir 1.14+
- PostgreSQL 14+
- Node.js (for asset build)

### Setup

```bash
# Clone the repository
git clone https://github.com/bradwbu/odyssie.git
cd odyssie

# Install dependencies
mix deps.get

# Create and migrate the database
mix ecto.setup

# Install Node.js dependencies (for Tailwind/esbuild)
cd assets && npm install && cd ..

# Start the Phoenix server
mix phx.server
```

The application will be available at `http://localhost:4000`.

### Environment Variables (Production)

```bash
DATABASE_URL=ecto://USER:PASS@HOST/DATABASE
SECRET_KEY_BASE=<generate with mix phx.gen.secret>
PHX_HOST=yourdomain.com
PORT=4000
```

## Key Design Decisions

1. **Cursor-based pagination** — More efficient than offset at scale, no duplicate/missing items
2. **Counter denormalization** — followers_count, following_count, posts_count on users table avoid expensive COUNT queries
3. **Deterministic DM channels** — `Enum.sort([user_a, user_b])` ensures both parties subscribe to the same PubSub topic
4. **PubSub from context layer** — Keeps LiveViews thin; contexts are the single source of truth for side effects
5. **UUID primary keys** — Avoids sequential ID enumeration, better for distributed systems
6. **Virtual fields on schemas** — liked_by_me, reposted_by_me computed at query time without extra JOINs

## License

MIT
