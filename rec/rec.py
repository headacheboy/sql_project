import pyodbc
import pandas as pd
from surprise import NormalPredictor,SVD,KNNBaseline
from surprise import Dataset
from surprise import Reader
from surprise.model_selection import cross_validate

def trainModel():
    userID = []
    itemID = []
    rating = []
    # the DSN value should be the name of the entry in odbc.ini, not freetds.conf
    # change the UID and PWD to your own
    conn = pyodbc.connect('DSN=MYMSSQL;UID=yourUID;PWD=yourPWD')
    crsr = conn.cursor()
    with crsr:
        crsr.execute("use DataMining")
        rows = crsr.execute("select users_ind, movies_ind, rating from users_movies").fetchall()

    crsr.close()
    conn.close()

    # make panda dataframe
    for i in rows:
        userID.append(i[0])    
        itemID.append(i[1])
        rating.append(i[2])

    rating_dict = {
        'userID': userID,
        'itemID': itemID,
        'rating': rating
    }
    df = pd.DataFrame(rating_dict)

    reader = Reader(rating_scale=(1, 5))
    data = Dataset.load_from_df(df[['userID', 'itemID', 'rating']], reader)
    trainset = data.build_full_trainset()
    sim_options = {'name': 'pearson_baseline', 'user_based': False}
    algo = KNNBaseline(sim_options=sim_options)
    # train
    algo.fit(trainset)
    return algo

# from movie index to movie name
def id2name(id):
    conn = pyodbc.connect('DSN=MYMSSQL;UID=yourUID;PWD=yourPWD')
    crsr = conn.cursor()
    with crsr:
        crsr.execute("use DataMining")
        res = crsr.execute("select title from movies_index, movies_year \
            where movies_index.movieId = movies_year.movieId \
            and movies_index.ind = " +  str(id)).fetchall()
        
    crsr.close()
    conn.close()
    
    return res[0][0]

def getRec(algo, movie_index):
    inner_id = algo.trainset.to_inner_iid(movie_index)
    neighbors = algo.get_neighbors(inner_id, 10) 
    rec_raw_ids = [algo.trainset.to_raw_iid(id) for id in neighbors]
    rec_movies = [id2name(id) for id in rec_raw_ids]
    for movie in rec_movies:
        print(movie)

if __name__ == '__main__':
    algo = trainModel()
    movie_index = 1
    getRec(algo, movie_index)
