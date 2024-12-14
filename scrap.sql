SELECT E1.Fname, E1.SSN, D1.Dname
FROM Department as D1 JOIN Employee as E1 ON D1.Mgrssn = E1.Ssn
WHERE EXISTS (SELECT D2.Number, COUNT(E2.SSN) 
                FROM Department as D2, Employee as E2
                WHERE D2.Mgrssn = E2.Ssn AND D2.Dnumber = D1.Dnumber
                GROUP BY D2.Dnumber
                HAVING COUNT(E2.Ssn) > 20)

SELECT E1.Fname, E1.SSN, D1.Dname
FROM Department as D1 JOIN Employee as E1 ON D1.Mgrssn = E1.Ssn
WHERE EXISTS (SELECT E2.Dno, COUNT(E2.Ssn)
                FROM Employee as E2
                WHERE E2.Dno = D1.Number
                GROUP BY E2.DNno
                HAVING COUNT(E2.Ssn) > 20)                