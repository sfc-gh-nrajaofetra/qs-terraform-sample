terraform {
  required_providers {
    snowflake = {
      source = "Snowflake-Labs/snowflake"
      version = "0.34.0"
    }
  }
}


provider "snowflake" {
  alias = "sys_admin"
  role  = "SYSADMIN"
}

resource "snowflake_database" "db" {
  provider = snowflake.sys_admin
  name     = "NRA_TF_DEMO_DB"
}

resource "snowflake_warehouse" "warehouse" {
  provider       = snowflake.sys_admin
  name           = "NRA_TF_DEMO_WH"
  warehouse_size = "small"

  auto_suspend = 60
}

 provider "snowflake" {
        alias = "security_admin"
        role  = "SECURITYADMIN"
    }


    resource "snowflake_role" "role" {
        provider = snowflake.security_admin
        name     = "NRA_TF_DEMO_SVC_ROLE"
    }


    resource "snowflake_database_grant" "grant" {
        provider          = snowflake.security_admin
        database_name     = snowflake_database.db.name
        privilege         = "USAGE"
        roles             = [snowflake_role.role.name]
        with_grant_option = false
    }


    resource "snowflake_schema" "schema" {
        provider   = snowflake.sys_admin
        database   = snowflake_database.db.name
        name       = "NRA_TF_DEMO_SCH"
        is_managed = false
    }


    resource "snowflake_schema_grant" "grant" {
        provider          = snowflake.security_admin
        database_name     = snowflake_database.db.name
        schema_name       = snowflake_schema.schema.name
        privilege         = "USAGE"
        roles             = [snowflake_role.role.name]
        with_grant_option = false
    }


    resource "snowflake_warehouse_grant" "grant" {
        provider          = snowflake.security_admin
        warehouse_name    = snowflake_warehouse.warehouse.name
        privilege         = "USAGE"
        roles             = [snowflake_role.role.name]
        with_grant_option = false
    }


    resource "tls_private_key" "svc_key" {
        algorithm = "RSA"
        rsa_bits  = 2048
    }


    resource "snowflake_user" "user" {
        provider          = snowflake.security_admin
        name              = "NRA_TF_SNOW"
        default_warehouse = snowflake_warehouse.warehouse.name
        default_role      = snowflake_role.role.name
        default_namespace = "${snowflake_database.db.name}.${snowflake_schema.schema.name}"
        rsa_public_key    = substr(tls_private_key.svc_key.public_key_pem, 27, 398)
    }


    resource "snowflake_role_grants" "grants" {
        provider  = snowflake.security_admin
        role_name = snowflake_role.role.name
        users     = [snowflake_user.user.name]
    }