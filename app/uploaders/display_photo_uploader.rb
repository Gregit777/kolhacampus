# encoding: utf-8

class DisplayPhotoUploader < BasePhotoUploader

  version :large do
    process resize_to_fill: [642, 482]
  end

  version :medium do
    process resize_to_fill: [481, 361]
  end

  version :small do
    process resize_to_fill: [321, 241]
  end

  version :tiny do
    process resize_to_fill: [160, 120]
  end

end
