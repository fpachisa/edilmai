"""Grant a Firebase custom role to a user (by uid or email).

Usage:
  python api/tools/grant_role.py --project <PROJECT_ID> --role author --email someone@example.com
  python api/tools/grant_role.py --project <PROJECT_ID> --role author --uid <UID>

Requires GOOGLE_APPLICATION_CREDENTIALS pointing to a service account JSON.
"""

import argparse
from typing import List
import firebase_admin
from firebase_admin import auth, credentials


def ensure_initialized(project_id: str | None):
    try:
        cred = credentials.ApplicationDefault()
        opts = {"projectId": project_id} if project_id else None
        firebase_admin.initialize_app(cred, opts)
    except ValueError:
        # already initialized
        pass


def add_role_to_user(uid: str, role: str):
    user = auth.get_user(uid)
    claims = user.custom_claims or {}
    roles: List[str] = list(claims.get("roles", []))
    if role not in roles:
        roles.append(role)
    claims["roles"] = roles
    auth.set_custom_user_claims(uid, claims)
    return roles


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--project", dest="project_id", required=False)
    p.add_argument("--role", required=True, help="role to grant, e.g., author")
    g = p.add_mutually_exclusive_group(required=True)
    g.add_argument("--uid")
    g.add_argument("--email")
    args = p.parse_args()

    ensure_initialized(args.project_id)

    if args.email:
        u = auth.get_user_by_email(args.email)
        uid = u.uid
    else:
        uid = args.uid

    roles = add_role_to_user(uid, args.role)
    print(f"Granted role '{args.role}' to user {uid}. Current roles: {roles}")


if __name__ == "__main__":
    main()

