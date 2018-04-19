class App < Sinatra::Base

	enable :sessions
	
		def set_error(error_message)
			session[:error] = error_message
		end
	
		def get_error()
			error = session[:error]
			session[:error] = nil
			return error
		end
	
		get('/') do
			slim(:index)
		end
	
		get('/register') do
			slim(:register)
		end

		get '/signup_successful' do
			slim(:signup_successful)
		end
	
		get('/error') do
			slim(:error)
		end
	
		get('/contacts/create') do
			slim(:create_contacts)
		end
	
		get('/contacts/:id/edit') do
	
			if(session[:user_id])
				db = SQLite3::Database.new('db/data.sqlite')
				db.results_as_hash = true
		
				result = db.execute("SELECT * FROM contacts WHERE user_id=?", [session[:user_id]])
				contact = result.first
	
				slim(:edit_contacts, locals:{contact:contact})
			else
				redirect('/')
			end
			
		end
	
		get('/contacts') do
			if(session[:user_id])
				db = SQLite3::Database.new('db/data.sqlite')
				db.results_as_hash = true
	
				result = db.execute("SELECT * FROM contacts WHERE user_id=?", [session[:user_id]])
	
				slim(:list_contacts, locals:{contacts:result})
			else
				redirect('/')
			end
		end
	
		post '/register' do
			db = SQLite3::Database.new('db/data.sqlite')
			db.results_as_hash = true
			username = params["username"]
			password = params["password"]
			confirm = params["confirm_password"]
			if confirm == password
				begin
					password = BCrypt::Password.create(password)
					db.execute("INSERT INTO users('username' , 'password_digest') VALUES(? , ?)", [username,password])
					redirect('/signup_successful')
	
				rescue SQLite3::ConstraintException
					session[:message] = "Username is not available"
					redirect("/error")
				end
			else
				session[:message] = "Password does not match"
				redirect("/error")
			end
			redirect('/')
		end
		
		
		post('/login') do
			db = SQLite3::Database.new('db/data.sqlite')
			db.results_as_hash = true
			username = params["username"]
			password = params["password"]
			
			result = db.execute("SELECT id, password_digest FROM users WHERE username=?", [username])
	
			if result.empty?
				set_error("Invalid")
				redirect('/error')
			end
	
			user_id = result.first["id"]
			password_digest = result.first["password_digest"]
			if BCrypt::Password.new(password_digest) == password
				session[:user_id] = user_id
				redirect('/contacts')
			else
				set_error("Invalid")
				redirect('/error')
			end
		end
	
		post('/logout') do
			session.destroy
			redirect('/')
		end
		
		post('/contacts/create') do
			if session[:user_id]
				db = SQLite3::Database.new('db/data.sqlite')
				db.results_as_hash = true
				contact_name = params["contact_name"]
				contact_number = params["contact_number"]
				
				db.execute("INSERT INTO contacts(user_id, contact_name, contact_number) VALUES (?,?,?)", [session[:user_id], contact_name, contact_number])
				redirect('/contacts')
			else
				redirect('/')
			end
		end
		
		post('/contacts/:id/delete') do
			if session[:user_id]
				contact_id = params[:id]
				db = SQLite3::Database.new('db/data.sqlite')
				db.results_as_hash = true
				result = db.execute("SELECT user_id FROM contacts WHERE id=?",[contact_id])
				if result.first["user_id"] == session[:user_id]
					db.execute("DELETE FROM contacts WHERE id=?",[contact_id])
					redirect('/contacts')
				end
			else
				redirect('/')
			end
		end
		
		post('/contacts/:id/update') do
			if session[:user_id]
				contact_id = params[:id]
				new_contact = params["contact_name"]
				new_contact2 = params["contact_number"]
	
				db = SQLite3::Database.new('db/data.sqlite')
				db.results_as_hash = true
				result = db.execute("SELECT user_id FROM contacts WHERE id=?",[contact_id])
				if result.first["user_id"] == session[:user_id]
					db.execute("UPDATE contacts SET contact_name=?, contact_number=? WHERE id=?",[new_contact, new_contact2, contact_id])
					redirect('/contacts')
				end
			else
				redirect('/')
			end
		end
	
	end                 
