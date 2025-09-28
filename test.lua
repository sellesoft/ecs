local test = " {hello 123}  "
print(test:match "%b{}":sub(2,-2))
