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
    conn = pyodbc.connect('DSN=MYMSSQL;UID=SA;PWD=Easton888')
    crsr = conn.cursor()
    with crsr:
        crsr.execute("use DataMiningFull")
        rows = crsr.execute("select users_ind, movies_ind, rating from users_movies \
            where users_ind < 5000").fetchall()

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
    conn = pyodbc.connect('DSN=MYMSSQL;UID=SA;PWD=Easton888')
    crsr = conn.cursor()
    with crsr:
        crsr.execute("use DataMiningFull")
        res = crsr.execute("select title from movies_index, movies_year \
            where movies_index.movieId = movies_year.movieId \
            and movies_index.ind = " +  str(id)).fetchall()
    crsr.close()
    conn.close()
    
    return res[0][0]

def getRecByMovieSim(algo, user_id):
    conn = pyodbc.connect('DSN=MYMSSQL;UID=SA;PWD=Easton888')
    crsr = conn.cursor()
    with crsr:
        crsr.execute("use DataMiningFull")
        movies_index = crsr.execute("select top 3 movies_ind from users_movies um,users_index ui \
            where um.users_ind = ui.ind \
            and ui.userId =" + str(user_id) +
            " order by rating desc").fetchall()
   
    inner_ids = [algo.trainset.to_inner_iid(movie_index[0]) for movie_index in movies_index]
    neighbors = [algo.get_neighbors(inner_id, 5) for inner_id in inner_ids]
    rec_raw_ids = [algo.trainset.to_raw_iid(id) for id_list in neighbors for id in id_list]
    rec_raw_ids = list(set(rec_raw_ids))

    for id in rec_raw_ids:
        hasViewed = crsr.execute("select * from users_movies um, users_index ui \
            where um.users_ind = ui.ind \
            and ui.userId = " + str(user_id) + 
            " and movies_ind = " + str(id)).fetchall()
        if hasViewed:
            rec_raw_ids.remove(id)
    crsr.close()
    conn.close()

    rec_movies = [id2name(id) for id in rec_raw_ids]
    print("Recommend Movies:")
    for movie in rec_movies:
        print(movie)

def getRecByUserSim(user_id):
    rec_raw_ids = []
    conn = pyodbc.connect('DSN=MYMSSQL;UID=SA;PWD=Easton888')
    crsr = conn.cursor()
    with crsr:
        crsr.execute("use DataMiningFull")
        users_sim = crsr.execute("select top 3 userId2 from users_relation \
            where userId1 = " + str(user_id) +
            "order by similarity").fetchall()
        for user in users_sim:
            user_movie = crsr.execute("select top 5 movies_ind from users_movies um,users_index ui \
            where um.users_ind = ui.ind \
            and ui.userId =" + str(user[0]) +
            " order by rating desc").fetchall()
            for movie in user_movie:
                rec_raw_ids.append(movie[0])
        rec_raw_ids = list(set(rec_raw_ids))
        for id in rec_raw_ids:
            hasViewed = crsr.execute("select * from users_movies um, users_index ui \
                where um.users_ind = ui.ind \
                and ui.userId = " + str(user_id) + 
                " and movies_ind = " + str(id)).fetchall()
            if hasViewed:
                rec_raw_ids.remove(id)
    crsr.close()
    conn.close()

    rec_movies = [id2name(id) for id in rec_raw_ids]
    print("Recommend Movies:")
    for movie in rec_movies:
        print(movie)
        

if __name__ == '__main__':
    user_id = input("please input user id(0 for exit):")
    if(user_id != '0'):
        perference = input("get recommend by similar users or movies?(0 for users, 1 for movies):")
        if(perference == '1'):
            algo = trainModel()
            while(user_id != '0'):
                getRecByMovieSim(algo, user_id)
                user_id = input("please input user id(0 for exit):")
        else:
            while(user_id != '0'):
                getRecByUserSim(user_id)
                user_id = input("please input user id(0 for exit):")
