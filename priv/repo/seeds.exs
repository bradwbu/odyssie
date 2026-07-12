alias Odyssie.Repo
alias Odyssie.Accounts.User

# Create admin account
case Repo.get_by(User, email: "bradleydurham@icloud.com") do
  nil ->
    %User{}
    |> User.registration_changeset(%{
      username: "brad",
      display_name: "Brad",
      email: "bradleydurham@icloud.com",
      password: "Givenchy*8652",
      is_admin: true,
      is_verified: true
    })
    |> Repo.insert!()
    |> then(&IO.puts("Admin account created: #{&1.email} (#{&1.username})"))

  user ->
    user
    |> Ecto.Changeset.change(%{is_admin: true, is_verified: true})
    |> Repo.update!()
    |> then(&IO.puts("Admin account updated: #{&1.email} (#{&1.username})"))
end
