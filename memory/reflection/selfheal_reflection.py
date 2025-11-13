import sqlite3, pandas as pd
from sklearn.ensemble import IsolationForest

DB = "~/etherverse/memory/data/hive_local.db"

def selfheal():
    conn = sqlite3.connect(os.path.expanduser(DB))
    df = pd.read_sql("SELECT length(content) as size FROM memories",conn)
    model = IsolationForest(contamination=0.03).fit(df)
    df['outlier'] = model.predict(df[['size']])
    issues = df[df.outlier == -1]
    print("[⚕️] Found", len(issues), "anomalies")
    conn.close()

if __name__ == "__main__":
    selfheal()
