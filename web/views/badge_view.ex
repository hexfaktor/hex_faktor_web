defmodule HexFaktor.BadgeView do
  use HexFaktor.Web, :view

  alias HexFaktor.Project

  def grade_color("A", _), do: "#46b01e"

  def grade_color("B", _), do: "#88cc33"

  def grade_color("C", _), do: "#FFE100"

  def grade_color("D", _), do: "#FF911D"

  #def grade_color("A", %Project{active: true}), do: "#46b01e"
  #def grade_color("A", %Project{active: false}), do: "#999999"

  #def grade_color("B", %Project{active: true}), do: "#88cc33"
  #def grade_color("B", %Project{active: false}), do: "#909090"

  #def grade_color("C", %Project{active: true}), do: "#FFE100"
  #def grade_color("C", %Project{active: false}), do: "#7b7b7b"

  #def grade_color("D", %Project{active: true}), do: "#FF911D"
  #def grade_color("D", %Project{active: false}), do: "#7b7b7b"

  def grade_color(_, _), do: "#bbb"
end
