from flask import Flask, request, jsonify
from sqlalchemy import create_engine, Table, MetaData, Column, String, Integer, and_
import logging

app = Flask(__name__)

app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///reservations.db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

engine = create_engine(app.config['SQLALCHEMY_DATABASE_URI'])
metadata = MetaData()

bookings = Table(
    'bookings', metadata,
    Column('id', Integer, primary_key=True),
    Column('room_number', String, nullable=False),
    Column('purpose', String, nullable=False),
    Column('club_name', String, nullable=False),
    Column('start_time', String, nullable=False),
    Column('end_time', String, nullable=False)
)

metadata.create_all(engine)

# Configure logging
logging.basicConfig(level=logging.DEBUG)

@app.route('/bookings', methods=['POST'])
def book_room():
    data = request.json
    room_number = data['room_number']
    start_time = data['start_time']
    end_time = data['end_time']

    try:
        with engine.begin() as connection:
            # Check for overlapping bookings
            overlapping_bookings = connection.execute(
                bookings.select().where(
                    and_(
                        bookings.c.room_number == room_number,
                        bookings.c.start_time < end_time,
                        bookings.c.end_time > start_time
                    )
                )
            ).fetchone()

            if overlapping_bookings:
                return jsonify({'message': 'Room is already booked for this time slot'}), 409

            # Insert new booking
            connection.execute(
                bookings.insert().values(
                    room_number=room_number,
                    purpose=data['purpose'],
                    club_name=data['club_name'],
                    start_time=start_time,
                    end_time=end_time
                )
            )
            return jsonify({'message': 'Booking successful!'}), 201
    except Exception as e:
        app.logger.error('Error booking room: %s', e)
        return jsonify({'error': 'Internal server error'}), 500

@app.route('/bookings', methods=['GET'])
def get_bookings():
    try:
        with engine.connect() as connection:
            # Fetch all bookings and format them as a list of dictionaries
            result = connection.execute(bookings.select())
            bookings_list = [
                {'id': row.id, 'room_number': row.room_number, 'purpose': row.purpose, 'club_name': row.club_name, 'start_time': row.start_time, 'end_time': row.end_time}
                for row in result
            ]
        return jsonify(bookings_list), 200
    except Exception as e:
        app.logger.error('Error fetching bookings: %s', e)
        return jsonify({'error': 'Internal server error'}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
