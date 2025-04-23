# 🧾 Information Management System (IMS)

A unified platform for managing HR, inventory, training, and operations. Built with [Elixir](https://elixir-lang.org/), [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view), and PostgreSQL, the IMS project streamlines internal processes through real-time interactivity, audit tracking, and modular architecture.

---

## 🔧 Tech Stack

- **Elixir** (>= 1.14)
- **Phoenix Framework** (>= 1.7)
- **Phoenix LiveView** for real-time UI
- **PostgreSQL** for database storage
- **Oban** for background jobs and scheduling
- **Tailwind CSS** for styling
- **Ecto** for data persistence
- **XLSXir / Elixlsx** for Excel export

---

## 📂 Project Structure

---

## 🚀 Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/your-org/ims.git
cd ims
```

### 2. Install Dependencies

```bash
mix deps.get
cd assets && npm install && cd ..
```

### 3. Set Up the Database

```bash
# Create and migrate the database
mix ecto.setup
```

### 4. Start the Phoenix Server

```bash
mix phx.server
```

### 5. Access the Application

Open your web browser and navigate to `http://localhost:4000`.

### 6. Create a .env or set system environment variables
- copy `dev.example.exs` to `dev.exs` and set your environment variables.


### 7. Run Tests

```bash
mix test
```


### ⚙️ Common Mix Tasks
- `mix phx.gen.live` – Generate LiveView CRUD
- `mix ecto.gen.migration` – Generate migrations
- `mix oban.check` – Check background job config

### 📤 Export Features
- **Excel Reports**: Export filtered data using XLSXir or Elixlsx
- **PDF Generation**: (Planned, add library like pdf_generator)
- **Audit Trail**: Tracks user actions across key modules

### � Key Modules
- **Accounts** – User management, roles, and permissions
- **HR** – Leave requests, away requests, training records
- **Inventory** – Asset allocation, logs, and tracking
- **Audit** – ISO-compliant audit reports and findings
- **Reports** – Data exports, summaries, and analytics

### 🧰 Oban Jobs
Jobs are scheduled for tasks such as:
- Leave balance automation
- Training reminders
- Inventory stock alerts
- Away request status updates

You can enqueue jobs manually:
```elixir
Ims.Workers.LeaveBalanceUpdaterWorker.new(%{}) |> Oban.insert()