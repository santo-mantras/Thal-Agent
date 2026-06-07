import sys
from database import engine, Base
import models

def main():
    print("Creating new tables...")
    Base.metadata.create_all(bind=engine)
    print("Done.")

if __name__ == "__main__":
    main()
