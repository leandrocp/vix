defmodule Eips do
  alias Eips.Nif

  def create_operation(name) do
    Nif.nif_create_op(to_charlist(name))
  end

  def get_operation_args(op) do
    Nif.nif_get_op_arguments(op)
    |> Enum.map(fn {param_name, {param_class, gtype, priority, offset}, flags} ->
      %{
        param_name: to_string(param_name),
        spec: %{class: to_string(param_class), gtype: gtype, priority: priority, offset: offset},
        flags: flags
      }
    end)
  end

  def image_from_file(path) do
    Nif.nif_image_new_from_file(to_charlist(path))
  end

  def run_vips_operation(name, input_params) do
    Nif.nif_operation_call_with_args(name, input_params)
  end

  def write_vips_image(vips_image, path) do
    Nif.nif_image_write_to_file(vips_image, path)
  end

  ### TEST

  def vips_invert(input_vi) do
    [output_vi] =
      run_vips_operation(
        'invert',
        [{'in', input_vi}]
      )

    output_vi
  end

  def vips_flip(input_vi, direction) do
    [output_vi] =
      run_vips_operation(
        'flip',
        [{'in', input_vi}, {'direction', direction}]
      )

    output_vi
  end

  def vips_add(a_vi, b_vi) do
    [output_vi] =
      run_vips_operation(
        'add',
        [{'left', 'VipsImage', a_vi}, {'right', 'VipsImage', b_vi}]
      )

    output_vi
  end

  def vips_affine(a_vi, vips_double_array) do
    [output_vi] =
      run_vips_operation(
        'affine',
        [{'in', a_vi}, {'matrix', vips_double_array}, {'extend', 3}]
      )

    output_vi
  end

  def vips_embed(in_img, x, y, width, height, extend) do
    [out_img] =
      run_vips_operation(
        'embed',
        [
          {'in', in_img},
          {'x', x},
          {'y', y},
          {'width', width},
          {'height', height},
          {'extend', extend}
        ]
      )

    out_img
  end

  defp to_double(n), do: n * 1.0

  def run_vips_affine(input, int_list, output) do
    input = to_charlist(input)
    output = to_charlist(output)

    double_list = Enum.map(int_list, &to_double/1)
    vips_double_array = Eips.Nif.nif_double_array(double_list)

    {:ok, vi} = image_from_file(input)
    output_vi = vips_affine(vi, vips_double_array)
    write_vips_image(output_vi, output)
  end

  def run_vips_embed(input, output, x, y, width, height, extend \\ :VIPS_EXTEND_MIRROR) do
    input = to_charlist(input)
    output = to_charlist(output)

    {:ok, vi} = image_from_file(input)
    output_vi = vips_embed(vi, x, y, width, height, extend)
    write_vips_image(output_vi, output)
  end

  def run_example(input_a, input_b, output) do
    input_a = to_charlist(input_a)
    input_b = to_charlist(input_b)
    output = to_charlist(output)

    {:ok, a_vi} = image_from_file(input_a)
    {:ok, _b_vi} = image_from_file(input_b)

    output_vi =
      vips_flip(a_vi, :VIPS_DIRECTION_HORIZONTAL)
      |> vips_invert()

    write_vips_image(output_vi, output)
  end

  # def vips_invert(input_path, output_path) do
  #   input_path = to_charlist(input_path)
  #   output_path = to_charlist(output_path)

  #   {:ok, im} = image_from_file(input_path)
  #   {:ok, gim} = Nif.nif_vips_object_to_g_object(im)

  #   [{'out', 'VipsImage', output_image}] =
  #     run_vips_operation(
  #       'invert',
  #       [{'in', 'VipsImage', gim}],
  #       [{'out', 'VipsImage'}]
  #     )

  #   vips_image = Nif.nif_g_object_to_vips_object(output_image)
  #   write_vips_image(vips_image, output_path)
  # end

  # def vips_add(image_a, image_b, output_path) do
  #   image_a = to_charlist(image_a)
  #   image_b = to_charlist(image_b)
  #   output_path = to_charlist(output_path)

  #   {:ok, img_a} = image_from_file(image_a)
  #   {:ok, img_a} = Nif.nif_vips_object_to_g_object(img_a)

  #   {:ok, img_b} = image_from_file(image_b)
  #   {:ok, img_b} = Nif.nif_vips_object_to_g_object(img_b)

  #   [{'out', 'VipsImage', output_image}] =
  #     run_vips_operation(
  #       'add',
  #       [{'left', 'VipsImage', img_a}, {'right', 'VipsImage', img_b}],
  #       [{'out', 'VipsImage'}]
  #     )

  #   vips_image = Nif.nif_g_object_to_vips_object(output_image)
  #   write_vips_image(vips_image, output_path)
  # end
end
