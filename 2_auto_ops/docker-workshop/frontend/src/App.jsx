import { useState, useEffect } from "react"

const API_URL = "/api/todos/"

function App() {
	const [todos, setTodos] = useState([])
	const [newTodo, setNewTodo] = useState("")
	const [loading, setLoading] = useState(true)


	useEffect(() => {
		fetchTodos()
	}, [])

	const fetchTodos = () => {
		fetch(API_URL)
			.then(res => res.json())
			.then(data => {
				setTodos(data)
				setLoading(false)
			})
			.catch(err => {
				console.error("Error fetching todos:", err)
				setLoading(false)
			})
	}


	const addTodo = e => {
		e.preventDefault()
		if (!newTodo.trim()) return

		fetch(API_URL, {
			method: "POST",
			headers: { "Content-Type": "application/json" },
			body: JSON.stringify({ title: newTodo, completed: false }),
		})
			.then(res => res.json())
			.then(data => {
				setTodos([data, ...todos])
				setNewTodo("")
			})
	}


	const toggleTodo = todo => {
		fetch(`${API_URL}${todo.id}/`, {
			method: "PUT",
			headers: { "Content-Type": "application/json" },
			body: JSON.stringify({ ...todo, completed: !todo.completed }),
		})
			.then(res => res.json())
			.then(updatedTodo => {
				setTodos(todos.map(t => (t.id === updatedTodo.id ? updatedTodo : t)))
			})
	}


	const deleteTodo = id => {
		fetch(`${API_URL}${id}/`, { method: "DELETE" }).then(() => {
			setTodos(todos.filter(t => t.id !== id))
		})
	}

	return (
		<div className="app-wrapper">
			<div className="container">
				<header className="header">
					<h1>My Tasks</h1>
				</header>

				<form onSubmit={addTodo} className="input-group">
					<input
						type="text"
						value={newTodo}
						onChange={e => setNewTodo(e.target.value)}
						placeholder="What needs to be done?"
						className="task-input"
					/>
					<button type="submit" className="add-btn">
						<svg
							width="24"
							height="24"
							viewBox="0 0 24 24"
							fill="none"
							stroke="currentColor"
							strokeWidth="2"
							strokeLinecap="round"
							strokeLinejoin="round">
							<line x1="12" y1="5" x2="12" y2="19"></line>
							<line x1="5" y1="12" x2="19" y2="12"></line>
						</svg>
					</button>
				</form>

				<div className="task-container">
					{loading ? (
						<div className="loading-state">
							<div className="spinner"></div>
							<p>Syncing...</p>
						</div>
					) : (
						<ul className="task-list">
							{todos.map(todo => (
								<li key={todo.id} className={`task-item ${todo.completed ? "completed" : ""}`}>
									<label className="checkbox-container">
										<input type="checkbox" checked={todo.completed} onChange={() => toggleTodo(todo)} />
										<span className="checkmark"></span>
									</label>

									<span className="task-text" onClick={() => toggleTodo(todo)}>
										{todo.title}
									</span>

									<button onClick={() => deleteTodo(todo.id)} className="delete-btn" title="Delete task">
										{/* SVG Icon สำหรับปุ่มลบ */}
										<svg
											width="18"
											height="18"
											viewBox="0 0 24 24"
											fill="none"
											stroke="currentColor"
											strokeWidth="2"
											strokeLinecap="round"
											strokeLinejoin="round">
											<polyline points="3 6 5 6 21 6"></polyline>
											<path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path>
											<line x1="10" y1="11" x2="10" y2="17"></line>
											<line x1="14" y1="11" x2="14" y2="17"></line>
										</svg>
									</button>
								</li>
							))}
							{todos.length === 0 && (
								<div className="empty-state">
									<div className="empty-icon">🎉</div>
									<p>All caught up! No tasks left.</p>
								</div>
							)}
						</ul>
					)}
				</div>
			</div>
		</div>
	)
}

export default App
