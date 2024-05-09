from flask import Flask, jsonify
from flask_sqlalchemy import SQLAlchemy

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'mysql://root:123456@localhost:3306/ghdetail'  # 替换成你的数据库连接信息
db = SQLAlchemy(app)

class User(db.Model):
    __tablename__ = 'housedetail' #* table name

    hid = db.Column(db.Integer, primary_key=True)    #* colume1
    title = db.Column(db.String(50), nullable=False) #* colume2

@app.route('/get_users', methods=['GET'])
def get_users():
    users = User.query.all()
    user_list = [{'hid': user.hid, 'title': user.title} for user in users]
    return jsonify(user_list)

if __name__ == '__main__':
    app.run(debug=True)