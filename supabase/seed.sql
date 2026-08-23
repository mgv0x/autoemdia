-- seed.sql
-- Valores de referência (categorias). O app não depende de tabelas de lookup,
-- mas este seed documenta as categorias oficiais e permite futura normalização.

-- Nota: as categorias são usadas como texto nas próprias tabelas de negócio
-- (maintenance_records.category, expenses.category) para simplificar consultas
-- e filtros no app. Caso queira normalizar futuramente, crie as tabelas
-- `maintenance_categories` e `expense_categories` e troque as colunas por FK.

-- Categorias oficiais de manutenção (documentação no app):
-- Óleo e filtros, Freios, Pneus, Motor, Suspensão, Elétrica,
-- Ar-condicionado, Transmissão, Alinhamento, Bateria,
-- Documentação, Seguro, Lavagem, Outros.

-- Categorias oficiais de gastos:
-- Manutenção, Combustível, Seguro, Documentação,
-- Lavagem, Peças, Outros.
