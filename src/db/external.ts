import { pgTable, text, uuid } from "drizzle-orm/pg-core";

/** Tables of other owners that UGC rows reference or read (read only). */
export const users = pgTable("users", { id: uuid("id").primaryKey(), status: text("status").notNull() });
export const companies = pgTable("companies", { id: uuid("id").primaryKey() });
