local DECLARATION = [[
	UI Framework alpha v1.1.0 - custom theme component
	Copyright (C) 2023 blakintosh

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <https://www.gnu.org/licenses/>.
]]

-- Add your theme here, or import, etc. see docs for schema.
-- e.g. UIF.ImportTheme("themes.MyTheme"). Passing a string will require it and get the export table it provides, otherwise you can provide a table directly.

UIF.ImportTheme({
	Fonts = {
		ASans = "fonts/ASansBlack.ttf"
	},
	Colors = {
        Black = {0, 0, 0},
        White = {1, 1, 1},
    }
})