# +
## Put direct turtle commands into scope for ipyturtle
# -

from ipyturtle import Turtle

#Create a turtle instance
_t = Turtle()

#Map essential turtle commands onto it
forward = _t.forward
left = _t.left
right = _t.right
penup = _t.penup
pendown = _t.pendown
reset = _t.reset
close_turtle = _t.close

#Render the ipyturtle widget
display(_t)
