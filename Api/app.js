const express = require('express');
const mongoose = require('mongoose');

const app = express();
module.exports = {app};

const { ServerApiVersion } = require('mongodb');

mongoose.connect('mongodb://localhost:27017/foodstore')
  .then(() => console.log('Kết nối database thành công!'))
  .catch(err => console.error('Lỗi kết nối:', err));