-- Configuration des extensions nécessaires
create extension if not exists "uuid-ossp";

-- Table des utilisateurs (ajout du champ mot de passe)
create table users (
    id uuid primary key default uuid_generate_v4(),
    email text unique not null,
    password text not null, -- Mot de passe de l'utilisateur
    created_at timestamp with time zone default now(),
    updated_at timestamp with time zone default now()
);

-- Table des comptes (Accueil, Bureau, Livre de Caisse, etc.)
create table accounts (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid references users(id) on delete cascade,
    name text not null,
    created_at timestamp with time zone default now(),
    updated_at timestamp with time zone default now()
);

-- Table des chantiers (anciennement "projects" sans l'attribut `status`, avec budget max)
create table chantiers (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid references users(id) on delete cascade,
    name text not null,
    budget_max decimal(12,2), -- Budget maximum alloué
    start_date date,
    end_date date,
    created_at timestamp with time zone default now(),
    updated_at timestamp with time zone default now()
);

-- Table du personnel (avec le champ salaire_max pour le salaire maximal)
create table personnel (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid references users(id) on delete cascade,
    name text not null,
    role text,
    contact text,
    salaire_max decimal(12,2), -- Salaire maximum à payer
    created_at timestamp with time zone default now(),
    updated_at timestamp with time zone default now()
);

-- Table des modes de paiement
create table payment_methods (
    id uuid primary key default uuid_generate_v4(),
    name text not null,
    created_at timestamp with time zone default now()
);

-- Table des types de paiement (liée aux chantiers de construction)
create table payment_types (
    id uuid primary key default uuid_generate_v4(),
    name text not null,
    category text check (category in ('revenu', 'dépense')),
    created_at timestamp with time zone default now()
);

-- Table des transactions
create table transactions (
    id uuid primary key default uuid_generate_v4(),
    account_id uuid references accounts(id) on delete cascade,
    chantier_id uuid references chantiers(id),
    personnel_id uuid references personnel(id),
    payment_method_id uuid references payment_methods(id),
    payment_type_id uuid references payment_types(id),
    description text,
    amount decimal(12,2) not null,
    transaction_date timestamp with time zone default now(),
    type text check (type in ('reçu', 'payé')),
    created_at timestamp with time zone default now(),
    updated_at timestamp with time zone default now()
);

-- Table des todos (dépenses planifiées, avec personnel et lien aux transactions)
create table todos (
    id uuid primary key default uuid_generate_v4(),
    account_id uuid references accounts(id) on delete cascade,
    chantier_id uuid references chantiers(id),
    personnel_id uuid references personnel(id), -- Ajout du personnel dans la table `todos`
    description text not null,
    estimated_amount decimal(12,2),
    due_date date,
    payment_method_id uuid references payment_methods(id), -- Méthode de paiement
    payment_type_id uuid references payment_types(id),     -- Type de paiement
    completed boolean default false,                       -- Indique si la tâche est terminée
    created_at timestamp with time zone default now(),
    updated_at timestamp with time zone default now()
);

-- Fonction pour mettre à jour le timestamp updated_at
create or replace function update_updated_at_column()
returns trigger as $$
begin
    new.updated_at = now();
    return new;
end;
$$ language plpgsql;

-- Triggers pour la mise à jour automatique de updated_at
create trigger update_users_updated_at
    before update on users
    for each row
    execute function update_updated_at_column();

create trigger update_accounts_updated_at
    before update on accounts
    for each row
    execute function update_updated_at_column();

create trigger update_chantiers_updated_at
    before update on chantiers
    for each row
    execute function update_updated_at_column();

create trigger update_personnel_updated_at
    before update on personnel
    for each row
    execute function update_updated_at_column();

create trigger update_transactions_updated_at
    before update on transactions
    for each row
    execute function update_updated_at_column();

create trigger update_todos_updated_at
    before update on todos
    for each row
    execute function update_updated_at_column();

-- Fonction pour insérer automatiquement une transaction quand un todo est complété
create or replace function insert_transaction_on_todo_completion()
returns trigger as $$
begin
    if new.completed = true and old.completed = false then
        insert into transactions (
            account_id,
            chantier_id,
            personnel_id,
            payment_method_id,
            payment_type_id,
            description,
            amount,
            transaction_date,
            type,
            created_at,
            updated_at
        ) values (
            new.account_id,
            new.chantier_id,
            new.personnel_id,
            new.payment_method_id,
            new.payment_type_id,
            new.description,
            new.estimated_amount,
            now(),
            'payé',
            now(),
            now()
        );
    end if;
    return new;
end;
$$ language plpgsql;

-- Trigger pour appeler la fonction lors de la mise à jour des todos
create trigger todo_completion_to_transaction
    after update on todos
    for each row
    when (new.completed = true and old.completed = false)
    execute function insert_transaction_on_todo_completion();

-- Insertion des données de base pour les modes de paiement
insert into payment_methods (name) values
    ('Espèces'),
    ('Chèque'),
    ('Virement bancaire'),
    ('Carte bancaire'),
    ('Mobile Money');

-- Insertion des données de base pour les types de paiement (liés aux chantiers de construction)
insert into payment_types (name, category) values
    ('Salaire personnel', 'dépense'),
    ('Achat matériel', 'dépense'),
    ('Divers', 'dépense'),
    ('Investissement', 'revenu'),
    ('Remboursement', 'revenu');

-- Index pour améliorer les performances
create index idx_transactions_account_id on transactions(account_id);
create index idx_transactions_chantier_id on transactions(chantier_id);
create index idx_transactions_personnel_id on transactions(personnel_id);
create index idx_transactions_date on transactions(transaction_date);
create index idx_todos_account_id on todos(account_id);
create index idx_todos_chantier_id on todos(chantier_id);
create index idx_todos_personnel_id on todos(personnel_id);
create index idx_todos_completed on todos(completed);
